require 'active_model/errors'

module ActiveModel
  class Errors
    def merge!(other)
      @messages.merge!(other.messages) { |_, ary1, ary2| ary1 + ary2 }
      @details.merge!(other.details) { |_, ary1, ary2| ary1 + ary2 }
    end
  end
end
