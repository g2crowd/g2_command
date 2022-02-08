module Command
  module TestHelper
    class ProxyCommand
      include Command

      option :error_list
      option :return_value

      def execute
        error_list.each do |(key, value)|
          errors.add(key.to_sym, value.to_s)
        end

        return_value
      end
    end

    def create_outcome(errors: {}, value: nil)
      ProxyCommand.run(error_list: errors, return_value: value)
    end
  end
end
