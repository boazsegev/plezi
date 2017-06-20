module Plezi
  module Base
    module Identification
      @ppid = ::Process.pid
      # returns a Plezi flavored pid UUID, used to set the pub/sub channel when scaling
      def pid
         process_pid = ::Process.pid
         if @ppid != process_pid
            @pid = nil
            @ppid = process_pid
         end
         @pid ||= SecureRandom.urlsafe_base64.tap { |str| @prefix_len = str.length }
      end
      # Converts a target Global UUID to a localized UUID
      def target2uuid(target)
         return nil unless target.start_with? pid
         target[@prefix_len..-1].to_i
      end

      # Extracts the machine part from a target's Global UUID
      def target2pid(target)
         target ? target[0..(@prefix_len - 1)] : Plezi.app_name
      end
    end
  end
end
