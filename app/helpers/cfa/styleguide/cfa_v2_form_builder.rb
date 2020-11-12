module Cfa
  module Styleguide
    class CfaV2FormBuilder < ActionView::Helpers::FormBuilder
      def cfa_text_input(method,
                         label_text,
                         required: false,
                         help_text: nil,
                         wrapper_options: {},
                         label_options: {},
                         **input_options)
        input_options[:'aria-required'] = true if required

        if help_text.present?
          help_text_id = help_text_id(method)
          input_options = append_to_value(input_options, :'aria-describedby', help_text_id)
          help_text_html = help_text_html(help_text, help_text_id)
        end

        if object.errors[method].any?
          wrapper_options = append_to_value(wrapper_options, :class, "form-group--error")
          error_id = error_id(method)
          input_options = append_to_value(input_options, :'aria-describedby', error_id)
          error_html = errors_for(object, method, error_id)
        end

        wrapper_options = append_to_value(wrapper_options, :class, "cfa-text-input form-group")
        @template.tag.div(wrapper_options) do
          @template.concat(@template.tag.div(class: "form-question") do
            label_with_optional_annotation(method, label_text, required, label_options)
          end)
          @template.concat(help_text_html&.html_safe)
          @template.concat(text_field(method, input_options))
          @template.concat(error_html&.html_safe)
        end
      end

      def cfa_button(label_text, wrapper_classes: [], options: {})
        @template.tag.div(class: "cfa-button #{wrapper_classes.join(' ')}") do
          button(label_text, { class: "button button--primary" }.merge(options))
        end
      end

      def cfa_radio(method, label_text, value, wrapper_classes: [], options: {})
        <<~HTML.html_safe
          <label class="cfa-radio radio-button #{wrapper_classes.join(' ')}">
            #{radio_button(method, value, options)}
            #{label_text}
          </label>
        HTML
      end

      def cfa_radiogroup(method, legend_text, wrapper_classes: [], options: {}, &block)
        field_set_options = {}
        if object.errors[method].any?
          error_id = error_id(method)
          field_set_options = append_to_value(field_set_options, :'aria-describedby', error_id)
        end

        @template.tag.div({ class: "cfa-radiogroup #{wrapper_classes.join(' ')}" }) do
          @template.field_set_tag(legend_text, field_set_options) do
            @template.tag.radiogroup(options) do
              output_html = ""
              output_html.concat(@template.capture(&block))
              output_html.concat(errors_for(object, method, error_id)) if object.errors[method].any?
              output_html.html_safe
            end
          end
        end
      end

      def cfa_select(
          method,
          label_text,
          choices,
          required: false,
          select_options: {},
          wrapper_options: {},
          label_options: {},
          **select_html_options,
          &block
        )
        select_html_options ||= {}

        if object.errors[method].any?
          wrapper_options = append_to_value(wrapper_options, :class, "form-group--error")
          error_id = error_id(method)
          error_html = errors_for(object, method, error_id)
          select_html_options = append_to_value(select_html_options, :'aria-describedby', error_id)
        end

        if required
          select_html_options[:'aria-required'] = true
        end

        wrapper_options = append_to_value(wrapper_options, :class, "cfa-select form-group")
        select_html_options = append_to_value(select_html_options, :class, "select__element")
        @template.tag.div(wrapper_options) do
          @template.concat(@template.tag.div(class: "form-question") do
            label_with_optional_annotation(method, label_text, required, label_options)
          end)
          @template.concat(@template.tag.div(class: "select") do
            select(method, choices, select_options, select_html_options, &block)
          end)
          @template.concat(error_html&.html_safe)
        end
      end

      def cfa_date_input(method,
                         label_text,
                         required: false,
                         help_text: nil,
                         wrapper_classes: [],
                         options: {})

        base_options = append_to_value(options, :class, "text-input date-input").merge(type: "number")
        base_options[:'aria-required'] = true if required

        helper_text_array = help_text ? help_text.split("/") : ["MM", "DD", "YYYY"]
        help_text_id = help_text_id(method)
        field_set_options = {}

        if object.errors[method].any?
          wrapper_classes.push("form-group--error")
          error_id = error_id(method)
          error_html = errors_for(object, method, error_id)
          base_options = append_to_value(base_options, :'aria-describedby', error_id)
          field_set_options = append_to_value(field_set_options, :'aria-describedby', error_id)
        end

        month_field = text_field(method, base_options.merge(
          value: object.send(method) ? object.send(method).month : nil,
          id: "#{object_name}_#{method}_2i",
          name: "#{object_name}[#{method}(2i)]",
          "aria-label": "Month #{helper_text_array[0]}",
          size: 2,
          placeholder: helper_text_array[0],
        ).merge(append_to_value(base_options, :class, "form-width--month")))

        day_field = text_field(method, base_options.merge(
          value: object.send(method) ? object.send(method).day : nil,
          id: "#{object_name}_#{method}_3i",
          name: "#{object_name}[#{method}(3i)]",
          "aria-label": "Day #{helper_text_array[1]}",
          size: 2,
          placeholder: helper_text_array[1],
        ).merge(append_to_value(base_options, :class, "form-width--day")))

        year_field = text_field(method, base_options.merge(
          value: object.send(method) ? object.send(method).year : nil,
          id: "#{object_name}_#{method}_1i",
          name: "#{object_name}[#{method}(1i)]",
          "aria-label": "Year #{helper_text_array[2]}",
          size: 4,
          placeholder: helper_text_array[2],
        ).merge(append_to_value(base_options, :class, "form-width--year")))

        @template.tag.div({ class: "cfa-date-input form-group #{wrapper_classes.join(' ')}" }) do
          @template.tag.fieldset(field_set_options) do
            <<~HTML.html_safe
              #{@template.tag.legend(label_text, 'aria-describedby': help_text_id)}
              #{help_text_html(helper_text_array.join('/'), help_text_id)}
              <div class="input-group--inline">
                  <div class="form-group date-input">
                   #{month_field}
                  </div>
                  <div class="date-input--separator">/</div>
                  <div class="form-group date-input">
                    #{day_field}
                  </div>
                  <div class="date-input--separator">/</div>
                  <div class="form-group date-input">
                    #{year_field}
                  </div>
              </div>
              #{error_html}
            HTML
          end
        end
      end

      def cfa_checkbox(method,
                       label_text,
                       checked_value = "1",
                       unchecked_value = "0",
                       wrapper_classes: [],
                       options: {})

        if object.errors[method].any?
          wrapper_classes.push("form-group--error")
          error_id = error_id(method)
          options = append_to_value(options, :'aria-describedby', error_id)
          error_html = errors_for(object, method, error_id)
        end

        label_classes = ["checkbox"]

        if options[:disabled]
          label_classes.push("is-disabled")
        end

        @template.tag.div({ class: "cfa-checkbox form-group input-group #{wrapper_classes.join(' ')}" }) do
          <<~HTML.html_safe
            <label class="#{label_classes.join(' ')}">
              #{check_box(method, options, checked_value, unchecked_value)} #{label_text}
            </label>
            #{error_html}
          HTML
        end
      end

      private

      def help_text_html(help_text, help_text_id)
        <<~HTML
          <div class="text--help" id="#{help_text_id}">
            #{help_text}
          </div>
        HTML
      end

      def label_with_optional_annotation(method, label_text, required, label_options)
        label(method, label_options) do
          @template.concat(<<~HTML.html_safe) if object.errors[method].any?
            <span class="sr-only">Validation error</span>
          HTML
          @template.concat label_text
          @template.concat(<<~HTML.html_safe) unless required
            <div class="form-question--optional"></div>
            <span class="sr-only">(Optional)</span>
          HTML
        end
      end

      def errors_for(object, method, error_id)
        errors = object.errors[method]
        <<~HTML
          <div class="text--error" id="#{error_id}">
            <i class="icon-warning"></i>
            #{errors.join(', ')}
          </div>
        HTML
      end

      def append_to_value(input_options, key, appending_value)
        initial_value = input_options[key]
        new_value = [initial_value, appending_value].compact.join(" ")
        input_options.merge({ key => new_value })
      end

      def help_text_id(method)
        "#{sanitized_id(method)}__help-text"
      end

      def error_id(method)
        "#{sanitized_id(method)}__errors"
      end

      def sanitized_id(method, position = nil)
        name = object_name.to_s.gsub(/([\[\(])|(\]\[)/, "_").gsub(/[\]\)]/, "")

        position ? "#{name}_#{method}_#{position}" : "#{name}_#{method}"
      end
    end
  end
end