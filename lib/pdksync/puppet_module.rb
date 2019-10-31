
require 'aasm'
require 'pdksync/logger'
require 'pdksync/utils'

module PdkSync
  class PuppetModule
    include AASM

    attr_reader :namespace, :module_name, :module_path

    def initialize(namespace, module_name, module_path = nil)
      module_path ||= File.join(module_name)
      @namespace = namespace
      @module_name = module_name
      @module_path = module_path
    end

    def create_commit(message, branch)
      raise ArgumentError 'Needs a branch_name and commit_message' if message.nil? || branch.nil?
      @message = message
      @branch = branch
      commit_code
    end

    def module_exists?
      File.exist?(module_path) && File.exist?(File.join(module_path, 'metadata.json'))
    end

    aasm do
      after_all_transitions :log_status_change
      error_on_all_events :log_error_event
      state :absent, initial: true
      state :present
      state :latest
      state :checking_out
      state :notifying
      state :files_staged
      state :merging_pr
      state :creating_pr
      state :pushing_branch
      state :creating_branch
      state :validating
      state :converting
      state :updating
      state :commmited
      state :cleaning_up

      event :ensure_present, after: :ensure_latest do
        before do
          PdkSync::Utils.clone_directory(namespace, module_name, module_path) unless module_exists?
        end
        error do |e|
          PdkSync::Logger.fatal e.message
        end
        transitions from: :absent, to: :present
      end

      event :ensure_latest, before_enter: :ensure_present do
        before do
          PdkSync::Utils.fetch_updates(module_path)
        end
        transitions from: [:absent, :present, :latest], to: :latest
      end

      event :commit_code, before_enter: :stage_files do
        transitions from: [:present, :latest], to: :commmited do
          guard do |*args|
            PdkSync::Utils.commit_staged_files(*args)
          end
        end
      end

      event :stage_files, before_enter: :checkout_branch do
      end

      event :checkout_branch do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :clean do
        transitions from: :running, to: :cleaning
      end

      event :convert do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :update do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :branch do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :validate do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :push_branch do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :create_pr do
        transitions from: [:running, :cleaning], to: :sleeping
      end

      event :merge_pr do
        transitions from: [:running, :cleaning], to: :sleeping
      end
    end

    def run_it(code, arg2)
      puts "horray! #{code} #{arg2}"
      true
    end

    def aasm_event_failed(event_name, old_state_name)
      # use custom exception/messages, report metrics, etc
    end

    def log_status_change
      PdkSync::Logger.debug "changing #{module_name} from #{aasm.from_state} to #{aasm.to_state}"
    end

    def log_error_event(e)
      PdkSync::Logger.fatal e.message
    end
  end
end
