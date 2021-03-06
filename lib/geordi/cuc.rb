require "rubygems"
require File.join(File.dirname(__FILE__), 'firefox_for_selenium')
require 'tempfile'

module Geordi
  class Cucumber

    VNC_DISPLAY = ':17'
    VNC_SERVER_COMMAND = "vncserver #{VNC_DISPLAY} -localhost -nolisten tcp -SecurityTypes None -geometry 1280x1024"
    VNC_VIEWER_COMMAND = "vncviewer #{VNC_DISPLAY}"
    VNC_ENV_VARIABLES = %w[DISPLAY BROWSER LAUNCHY_BROWSER]

    def run
      4.times { puts }
      puts "Running Cucumber tests..."
      puts "========================="

      consolidate_rerun_txt_files
      show_features_to_run

      setup_vnc

      command = use_parallel_tests? ? parallel_execution_command : serial_execution_command

      if argv.include? "-v"
        puts command
        2.times { puts }
      end

      2.times { puts }
      exec command
    end

    def launch_vnc_viewer
      fork {
        error = capture_stderr do
          system(VNC_VIEWER_COMMAND)
        end
        unless $?.success?
          if $?.exitstatus == 127
            puts "VNC viewer not found. Install it using cuc-vnc-setup."
          else
            puts "VNC viewer could not be opened:"
            puts error
          end
        end
      }
    end

    def restore_env
      VNC_ENV_VARIABLES.each do |variable|
        ENV[variable] = ENV["OUTER_#{variable}"]
      end
    end

    private

    attr_writer :argv
    def argv
      @argv ||= ARGV
    end

    def serial_execution_command
      format_args = spinner_available? ? ['--format', 'CucumberSpinner::CuriousProgressBarFormatter'] : ['--format', 'progress']
      [use_firefox_for_selenium, "b", "cucumber", format_args, escape_shell_args(argv)].flatten.compact.join(" ")
    end


    def parallel_execution_command
      puts "Using parallel_tests ...\n\n"
      self.argv = argv - command_line_features
      gem 'parallel_tests', parallel_tests_version
      require 'parallel_tests'
      type_arg = Gem::Version.new(::ParallelTests::VERSION) > Gem::Version.new('0.7.0') ? 'cucumber' : 'features'
      features_to_run = command_line_features
      features_to_run = find_all_features_recursively('features') if features_to_run.empty?
      features_to_run = features_to_run.join(" ")
      parallel_tests_args = "-t #{type_arg}"
      cucumber_args = command_line_args.empty? ? '' : "-o '#{escape_shell_args(command_line_args).join(" ")}'"
      [use_firefox_for_selenium, 'b parallel_test', parallel_tests_args, cucumber_args, "-- #{features_to_run}"].flatten.compact.join(" ")
    end


    def use_firefox_for_selenium
      path = Geordi::FirefoxForSelenium.path_from_config
      if path
        "PATH=#{Geordi::FirefoxForSelenium.path_from_config}:$PATH"
      end
    end


    def escape_shell_args(*args)
      args.flatten.collect do |arg|
        arg.gsub(/([\\ "])/) { |match| "\\#{$1}" }
      end
    end

    def show_features_to_run
      unless features_to_run.empty?
        passed_by = (features_to_run == rerun_txt_features && features_to_run != command_line_features) ? 'rerun.txt' : 'command line'
        2.times { puts }
        puts "features to run (passed by #{passed_by}):"
        puts "-----------------------------------------"
        puts features_to_run.join("\n")
        puts "-----------------------------------------"
      end
    end

    def features_to_run
      @features_to_run ||= begin
        features = command_line_features
        features = rerun_txt_features if features.empty?
        features
      end
    end

    def rerun_txt_features
      @rerun_txt_features ||= begin
        if File.exists?("rerun.txt")
          IO.read("rerun.txt").to_s.strip.split(/\s+/)
        else
          []
        end
      end
    end

    def command_line_features
      @command_line_features ||= begin
        index = argv.find_index("--")
        if index.nil? && argv.first && argv.first[0,1] != "-"
          find_all_features_recursively(argv)
        elsif index
          files_or_dirs = argv[index + 1 .. -1]
          find_all_features_recursively(files_or_dirs)
        else
          []
        end
      end
    end

    def command_line_args
      @command_line_args ||= begin
        index = argv.find_index("--")
        if index.nil? && argv.first && argv.first[0,1] == "-"
          argv
        elsif index
          argv[0 .. index-1]
        else
          []
        end
      end
    end

    def consolidate_rerun_txt_files
      parallel_rerun_files = Dir.glob("parallel_rerun*.txt")
      unless parallel_rerun_files.empty?
        2.times { puts }
        puts "consolidating parallel_rerun.txt files ..."

        rerun_content = []
        parallel_rerun_files.each do |filename|
          rerun_content << File.read(filename).strip
          File.unlink(filename)
        end

        File.open("rerun.txt", "w") do |f|
          f.puts(rerun_content.join(" "))
        end
      end
    end

    def find_all_features_recursively(files_or_dirs)
      Array(files_or_dirs).map do |file_or_dir|
        if File.directory?(file_or_dir)
          file_or_dir = Dir.glob(File.join(file_or_dir, "**", "*.feature"))
        end
        file_or_dir
      end.flatten.uniq.compact
    end

    def features_can_run_with_parallel_tests?(features)
      not features.any?{ |feature| feature.include? ":" }
    end


    # Check if cucumber_spinner is available
    def spinner_available?
      @spinner_available ||= File.exists?('Gemfile') && File.open('Gemfile').read.scan(/cucumber_spinner/).any?
    end


    # Check if parallel_tests is available
    def parallel_tests_available?
      not parallel_tests_version.nil?
    end

    # get the current parallel test version used in Gemfile.lock (nil if not available)
    def parallel_tests_version
      @parallel_tests_version ||= begin
        parallel_tests = `bundle list`.split("\n").detect{ |x| x =~ /parallel_tests/ }
        if parallel_tests
          parallel_tests.scan( /\(([\d\.]+).*\)/ ).flatten.first
        end
      end
    end

    def use_parallel_tests?
      parallel_tests_available? && features_can_run_with_parallel_tests?(features_to_run) && features_to_run.size != 1
    end

    def setup_vnc
      if try_and_start_vnc
        VNC_ENV_VARIABLES.each do |variable|
          ENV["OUTER_#{variable}"] = ENV[variable] if ENV[variable]
        end
        ENV["BROWSER"] = ENV["LAUNCHY_BROWSER"] = File.expand_path(File.join(File.dirname(__FILE__), '../../bin/launchy_browser'))
        ENV["DISPLAY"] = VNC_DISPLAY

        puts
        puts "Selenium is running in a VNC window. Use cuc-show to view it."
      end
    end

    def try_and_start_vnc
      # check if vnc is already running
      #return true if vnc_server_running?
      error = capture_stderr do
        system(VNC_SERVER_COMMAND)
      end
      case $?.exitstatus
      when 0,
        98 # was already running after all
        true
      when 127 # not installed
        puts "Could not launch VNC server. Install it by running cuc-setup-vnc."
        puts
        puts
        false
      else
        puts "Starting VNC failed:"
        puts error
        puts
        puts
        false
      end
    end

    def capture_stderr
      old_stderr = $stderr.dup
      io = Tempfile.new('cuc')
      $stderr.reopen(io)
      yield
      io.rewind
      io.read
    ensure
      io.close
      io.unlink
      $stderr.reopen(old_stderr)
    end

  end
end
