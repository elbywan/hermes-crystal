module Bindings::Utils
  macro ptr_to_string?(id)
    (String.new({{id}}.as(UInt8*)) if {{id}})
  end

  macro ptr_to_string(id)
    String.new({{id}}.as(UInt8*))
  end

  macro assign(id, &block)
    if {{id}} = @data["{{id}}"]
      {% if block %}
        c_data.{{id}} = {{ block.body }}
      {% else %}
        c_data.{{id}} = {{id}}
      {% end %}
    end
  end

  macro assign_bool(id)
    Bindings::Utils.assign {{id}} do
      @data["{{id}}"] ? 1_i8 : 0_i8
    end
  end

  macro ptr_of(exp)
    %temp = {{ exp }}
    %temp ? pointerof(%temp) : Pointer(typeof(%temp)).null
  end

  macro ptr_alloc(exp)
    %temp = {{ exp }}
    %temp ? Pointer.malloc(size: sizeof(typeof(%temp)), value: %temp) : Pointer(typeof(%temp)).null
  end

  macro mapping(type, skip_initialize = false, &block)
    property data : {{ type }}
    forward_missing_to @data
    def_equals @data

    {% if !skip_initialize %}
      {% if block %}
        def initialize(data)
          {{ yield }}
        end
      {% else %}
        def initialize(@data)
        end
      {% end %}
    {% end %}
  end

  macro struct_map(class_name, *args)
    class {{ class_name }} < Mapping
      alias DataType = {
        {% for arg in args %}{{ arg.var }}: {{ arg.type }},{% end %}
      }

      Utils.mapping(DataType) do
        @data = {
          {% for arg in args %}
            {% if arg.value && arg.value["from_data"] %}
              # Custom
              {{ arg.var }}: {{ arg.value["from_data"] }},
            {% elsif arg.type.resolve.union_types.includes? StringArray %}
              # Others
              {% if arg.type.resolve.nilable? %}
                {{ arg.var }}: data["{{ arg.var }}"].try { |v| StringArray.new(v) },
              {% else %}
                {{ arg.var }}: StringArray.new(data["{{ arg.var }}"]),
              {% end %}
            {% elsif arg.type.resolve.union_types.any? { |t| t < Mapping || t < ArrayMapping } %}
              # Mapping
              {% if arg.type.resolve.nilable? %}
                {{ arg.var }}: data["{{ arg.var }}"].try { |v| {{ arg.type.resolve.union_types.find { |t| t != Nil } }}.new(v) },
              {% else %}
                {{ arg.var }}: {{ arg.type }}.new(data["{{arg.var}}"]),
              {% end %}
            {% else %}
              # Default
              {{ arg.var }}: data["{{arg.var}}"],
            {% end %}
          {% end %}
        }
      end

      def initialize(c_data : LibHermes::C{{ class_name }})
          @data = {
            {% for arg in args %}
              {% if arg.value && arg.value["from_c"] %}
                # Custom
                {{ arg.var }}: {{ arg.value["from_c"] }},
              {% elsif arg.type.resolve.union_types.includes? StringArray %}
                # Others
                {% if arg.type.resolve.nilable? %}
                  {{ arg.var }}: (
                    %ptr = c_data.{{ arg.var }}
                    %ptr.null? ? nil : StringArray.new(%ptr.value)
                  ),
                {% else %}
                  {{ arg.var }}: StringArray.new(c_data.{{ arg.var }}.value),
                {% end %}
              {% elsif arg.type.resolve.union_types.any? { |t| t < Mapping || t < ArrayMapping } %}
                {% if arg.type.resolve.nilable? %}
                  {{ arg.var }}: ({{ arg.type.resolve.union_types.find { |t| t != Nil } }}.new(c_data.{{ arg.var }}{% if arg.value && arg.value["ptr"] %}.value{% end %}) if c_data.{{ arg.var }}),
                {% else %}
                  {{ arg.var }}: {{ arg.type }}.new(c_data.{{ arg.var }}{% if arg.value && arg.value["ptr"] %}.value{% end %}),
                {% end %}
              {% elsif arg.type.resolve.union_types.includes? Bool %}
                # Core value types
                {{ arg.var }}: c_data.{{ arg.var }} == 1,
              {% elsif arg.type.resolve.union_types.includes? String %}
                # Core reference types
                {% if arg.type.resolve.nilable? %}
                  {{ arg.var }}: ptr_to_string?(c_data.{{ arg.var }}),
                {% else %}
                  {{ arg.var }}: ptr_to_string(c_data.{{ arg.var }}),
                {% end %}
              {% else %}
                # Default
                {{ arg.var }}: c_data.{{arg.var}},
              {% end %}
            {% end %}
          }
      end

      def to_unsafe
          c_data = LibHermes::C{{ class_name }}.new

          {% for arg in args %}
            {% if arg.value && arg.value["to_c"] %}
              # Custom
              Bindings::Utils.assign {{ arg.var }} do
                {{ arg.value["to_c"] }}
              end
            {% elsif arg.type.resolve.union_types.includes? StringArray %}
              # Others
              Bindings::Utils.assign {{ arg.var }} do
                {% if arg.type.resolve.nilable? %}
                  @data["{{ arg.var }}"].try { |i| ptr_alloc(i.to_unsafe) }
                {% else %}
                  ptr_alloc(@data["{{ arg.var }}"].to_unsafe)
                {% end %}
              end
            {% elsif arg.type.resolve.union_types.any? { |t| t < Mapping || t < ArrayMapping } && arg.value && arg.value["ptr"] %}
              # Mapping pointer
              Bindings::Utils.assign {{ arg.var }} do
                ptr_alloc({{ arg.var }}.to_unsafe)
              end
            {% elsif arg.type.resolve.union_types.includes? Bool %}
              # Core value types
              Bindings::Utils.assign_bool {{ arg.var }}
            {% else %}
              # Default
              Bindings::Utils.assign {{ arg.var }}
            {% end %}
          {% end %}

          c_data
      end
    end
  end

  macro struct_array_map(
    class_name,
    type,
    dbl_ptr = false,
    from_data = nil,
    from_c = nil,
    to_c = nil,
    size_field = size,
    data_field = data,
    size_type = nil
  )
    class {{ class_name }} < ArrayMapping
      Utils.mapping Array({{ type }}) do
        {% if from_data %}
          @data = data.map do |elt|
            {{ from_data }}
          end
        {% elsif class_name.stringify == "StringArray" %}
          @data = data
        {% else %}
          @data = data.map do |elt|
            {{ type }}.new elt
          end
        {% end %}
      end

      def initialize(c_data : LibHermes::C{{ class_name }})
        size = c_data.{{ size_field }}
        @data = Array({{ type }}).new(
          size || 0
        )
        if c_data.{{ data_field }}
          (0...size).each do |i|
            elt = c_data.{{ data_field }}[i]
            %to_push = (
              {% if from_c %}{{ from_c }}{% elsif dbl_ptr %}{{ type }}.new elt.value{% else %}{{ type }}.new(elt){% end %}
            )
            @data << %to_push
          end
        else
          @data = [] of {{ type }}
        end
      end

      def to_unsafe
        LibHermes::C{{ class_name }}.new(
          {{ data_field }}: @data.map do |elt|
            {% if to_c %}
              {{ to_c }}
            {% elsif dbl_ptr %}
              ptr_alloc(elt.to_unsafe)
            {% else %}
            elt.to_unsafe
            {% end %}
          end,
          {{ size_field }}: {% if size_type %}{{ size_type }}.new {% end %}@data.size
        )
      end
    end
  end
end
