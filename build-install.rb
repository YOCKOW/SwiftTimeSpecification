#!/usr/bin/env ruby

=begin
build-install.rb
  © 2016 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
=end

require 'fileutils'
require 'optparse'
require 'shellwords'

def failed(message)
  $stderr.puts(message)
  exit
end

# Constants
OS = case RbConfig::CONFIG['host_os']
  when /darwin/i then :OS_X
  when /linux/i then :Linux
  else :Other
end
RequiredSwiftVersion = '2.0'
SharedLibraryPrefix = 'lib'
SharedLibrarySuffix = (OS == :OS_X) ? '.dylib' : '.so'
SourcesDirectory = File.expand_path(File.dirname(__FILE__) + "/Sources")
EscapedSourcesDirectory = Shellwords.shellescape(SourcesDirectory)
TargetSources = ['TimeSpecification.swift']
TestSources = ['main.swift', 'TAP.swift']
ModuleName = 'TimeSpecification'
ModuleLinkName = 'SwiftTimeSpecification'

failed("OS Not Supported: #{RbConfig::CONFIG['host_os']}") if OS == :Other

# Default Values
swiftc_path = 'swiftc'
swift_version = nil
build_directory = 'build'
build_include_directory = nil
build_lib_directory = nil
install = false
install_prefix = '/usr/local'
skip_build = false
skip_test = false
sdk = 'macosx'
clean = false

# Parsing Options
OptionParser.new(__FILE__){|parser|

  parser.on('--swiftc=PATH',
            'Path to the Swift compiler which you want to use.') {|path|
    swiftc_path = path
  }

  parser.on('--build-dir=PATH',
            'Name of the directory where the build products will be placed.') {|path|
    build_directory = path
  }

  parser.on('--install',
            'Whether to install products or not.') {|value|
    install = value
  }
  parser.on('--prefix=PATH', '--install-prefix=PATH',
            'The installation prefix.') {|path|
    install = true
    install_prefix = (path =~ /^~\//) ? File.expand_path(path) : path
    if File.exists?(install_prefix) && !File.directory?(install_prefix)
      failed(%Q["#{path}" is not directory.])
    elsif install_prefix !~ /^\//
      failed(%Q[The installation prefix must be absolute path.])
    end
  }

  parser.on('--skip-build',
            'Whether to skip building or not.') {|value|
    skip_build = value
  }
            
  parser.on('--skip-test',
            'Whether to skip testing or not.') {|value|
    skip_test = value
  }
            
  parser.on('--sdk=VALUE',
            '(OS X Only) SDK name to be passed to `xcrun`.'){|value|
    sdk = value
    failed("Invalid SDK Name: #{sdk}") if sdk !~ /\A[\.0-9A-Z_a-z]+\Z/
  }
            
  parser.on('--clean',
            'Whether to clean up or not.') {|value|
    clean = value
  }

  begin
    parser.parse!(ARGV)
  rescue  OptionParser::ParseError  => error
    failed(error.message + "\n" + parser.help)
  end
}

# Check SDK Name
if OS == :OS_X && !system(%Q[xcrun --sdk #{sdk} --show-sdk-path >/dev/null 2>&1])
  if $?.exitstatus == 127
    failed("'xcrun' does not exist.")
  else
    failed("Invalid SDK Name: #{sdk}")
  end
end

# Determine Swift Path
escaped_swiftc_path = Shellwords.shellescape(swiftc_path)
if !system(%Q[which #{escaped_swiftc_path} >/dev/null])
  failed("`swiftc` is not found.")
end
if OS == :OS_X
  escaped_swiftc_path = "xcrun --sdk #{sdk} #{escaped_swiftc_path}"
end

# Detect Swift Version
swift_version = %x[#{swiftc_path} --version]
if swift_version =~ /^(?:Apple\s+)?Swift\s+version\s+(\d+)((?:\.\d+)*)\s+/
  swift_version = Regexp.last_match(1) + Regexp.last_match(2)
  if (swift_version.split('.').map(&:to_i) <=> RequiredSwiftVersion.split('.').map(&:to_i)) < 0
    failed("The minimum required version of Swift is #{RequiredSwiftVersion}")
  end
else
  failed("Cannot detect the version of Swift: #{swift_version}")
end

# Expand path of `build_directory`
if build_directory !~ /^\//
  build_directory = File.expand_path(File.dirname(__FILE__) + "/#{build_directory}")
end
if OS == :OS_X && sdk && !sdk.empty?
  build_directory += "/#{sdk}"
end
build_include_directory = "#{build_directory}/include"
build_lib_directory = "#{build_directory}/lib"
escaped_build_directory = Shellwords.shellescape(build_directory)
escaped_build_include_directory = Shellwords.shellescape(build_include_directory)
escaped_build_lib_directory = Shellwords.shellescape(build_lib_directory)

# Print Options
puts("Options:")
puts(%Q[  Swift Compiler: #{swiftc_path}])
puts(%Q[  Swift Version: #{swift_version}])
puts(%Q[  The Build Directory: "#{build_directory}"])
if install
  puts(%Q[  The Installation Prefix: "#{install_prefix}"])
else
  puts(%Q[  No products will be installed.])
end
puts(%Q[  Skip building: #{skip_build ? "Yes" : "No"}])
puts(%Q[  Skip testing: #{skip_test ? "Yes" : "No"}])

# Let's start
## clean
if clean
  FileUtils.rm_r(build_directory)
end

## Create directories
if !skip_build || !skip_test
  FileUtils.mkdir_p(build_directory) if !File.exists?(build_directory)
  FileUtils.mkdir_p(build_include_directory) if !File.exists?(build_include_directory)
  FileUtils.mkdir_p(build_lib_directory) if !File.exists?(build_lib_directory)
end

## build
if !skip_build
  puts("===== BUILD =====")
  
  create_module =
    "#{escaped_swiftc_path} " +
    TargetSources.map{|file| "#{EscapedSourcesDirectory}/#{Shellwords.shellescape(file)}"}.join(' ') + ' ' +
    "-module-name #{ModuleName} " +
    "-module-link-name #{ModuleLinkName} " +
    "-emit-module-path #{escaped_build_include_directory}/#{ModuleName}.swiftmodule "
  puts("  Execute: #{create_module}")
  if !system(create_module)
    failed("Command exited with status #{$?.exitstatus}")
  end
  
  build_library =
    "#{escaped_swiftc_path} " +
    TargetSources.map{|file| "#{EscapedSourcesDirectory}/#{Shellwords.shellescape(file)}"}.join(' ') + ' ' +
    "-module-name #{ModuleName} " +
    "-emit-library " +
    "-o#{escaped_build_lib_directory}/#{SharedLibraryPrefix}#{ModuleLinkName}#{SharedLibrarySuffix}"
  puts("  Execute: #{build_library}")
  if !system(build_library)
    failed("Command exited with status #{$?.exitstatus}")
  end
  
  puts("...DONE")
end

## test
if !skip_test
  puts("===== TEST =====")
  
  test_executable = build_directory + '/test'
  escaped_test_executable = escaped_build_directory + '/test'
  if !File.exists?(test_executable)
    puts("Start building an executable")
    build_test =
      "#{escaped_swiftc_path} " +
      TestSources.map{|file| "#{EscapedSourcesDirectory}/#{Shellwords.shellescape(file)}"}.join(' ') + ' ' +
      "-o#{escaped_test_executable} " +
      "-I#{escaped_build_include_directory} " +
      "-L#{escaped_build_lib_directory}"
    puts("  Execute: #{build_test}")
    if !system(build_test)
      failed("Command exited with status #{$?.exitstatus}")
    end
  end
  
  puts("Start tests")
  if !system(%Q[LD_LIBRARY_PATH=#{escaped_build_lib_directory} #{escaped_test_executable}])
    failed("TEST FAILED.")
  end
  
  puts("..SUCCESSFUL")
end

## install
if install
  puts("===== INSTALL =====")
  
  include_directory = "#{install_prefix}/include"
  lib_directory = "#{install_prefix}/lib"
  
  FileUtils.mkdir_p(include_directory) if !File.exists?(include_directory)
  FileUtils.mkdir_p(lib_directory) if !File.exists?(lib_directory)

  copies = {
    "#{build_include_directory}/#{ModuleName}.swiftmodule" =>
      "#{include_directory}/#{ModuleName}.swiftmodule",
    "#{build_include_directory}/#{ModuleName}.swiftdoc" =>
      "#{include_directory}/#{ModuleName}.swiftdoc",
    "#{build_lib_directory}/#{SharedLibraryPrefix}#{ModuleLinkName}#{SharedLibrarySuffix}" =>
      "#{lib_directory}/#{SharedLibraryPrefix}#{ModuleLinkName}#{SharedLibrarySuffix}"
  }
  
  copies.each_pair{|src, dest|
    puts("install: #{src}\n =>         #{dest}")
    begin
      FileUtils.cp(src, dest)
    rescue
      failed("Installation Failed.")
    end
  }
  
  puts("...DONE.")
end
