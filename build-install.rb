#!/usr/bin/env ruby

=begin
build-install.rb
  © 2016 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
=end

require 'fileutils'
require 'json'
require 'optparse'
require 'pathname'
require 'shellwords'

# Constants
OS = case RbConfig::CONFIG['host_os']
  when /darwin/i then :OS_X
  when /linux/i then :Linux
  else :Other
end
RequiredSwiftVersion = '3.0'
SharedLibraryPrefix = 'lib'
SharedLibrarySuffix = (OS == :OS_X) ? '.dylib' : '.so'
SourcesDirectory = (Pathname(__FILE__).dirname + 'Sources').expand_path
LibrarySources = [
  'Library'
].map{|fn| Pathname(fn)}
TestSources = [
  'Test'
].map{|fn| Pathname(fn)}
ModuleName = 'TimeSpecification'
ModuleLinkName = 'SwiftTimeSpecification'

## Default Values
Defaults = {
  :swiftc => Pathname('swiftc'),
  :build_directory => Pathname('build'),
  :install => false,
  :prefix => Pathname('/usr/local'),
  :skip_build => false,
  :skip_test => false,
  :sdk => 'macosx',
  :clean => false
}

## Options
Options = {
  :swiftc => nil,
  :build_directory => nil,
  :install => nil,
  :prefix => nil,
  :skip_build => nil,
  :skip_test => nil,
  :sdk => nil,
  :clean => nil
}

# Functions
def failed(message)
  $stderr.puts(message)
  exit
end

def all_files_in_dir(dirname, basedir)
  files = []
  directory = basedir + dirname
  Dir.foreach(directory.to_s) {|filename|
    next if filename =~ /\A\.\.?\Z/
    path = directory + filename
    if path.directory?
      files.concat(all_files_in_dir(filename, directory))
    else
      files.push(path)
    end
  }
  return files
end
def all_files(list, rootdir)
  files = []
  list.each {|filename|
    path = rootdir + filename
    failed("#{path.to_s}: No such file or directory.") if !path.exist?
    if path.directory?
      files.concat(all_files_in_dir(filename, rootdir))
    elsif
      files.push(path)
    end
  }
  return files
end

# Extends class
class Pathname
  def escaped
    return Shellwords.shellescape(self.to_s)
  end
end

# Parsing Options
OptionParser.new(__FILE__){|parser|
  parser.on('--swiftc=PATH',
            'Path to the Swift compiler which you want to use.') {|path|
    Options[:swiftc] = Pathname(path)
  }
  parser.on('--build-dir=PATH', '--build-directory=PATH',
            'Name of the directory where the build products will be placed.') {|path|
    Options[:build_directory] = Pathname(path)
  }
  parser.on('--install',
            'Whether to install products or not.') {|value|
    Options[:install] = value
  }
  parser.on('--prefix=PATH', '--install-prefix=PATH',
            'The installation prefix.') {|path|
    Options[:prefix] = Pathname(path)
    Options[:prefix]= Options[:prefix].expand_path if path =~ /\A~\//
    if !Options[:prefix].absolute?
      failed(%Q[The installation prefix must be absolute path.])
    elsif Options[:prefix].exist? && !Options[:prefix].directory?
      failed(%Q["#{path}" is not directory.])
    end
  }
  parser.on('--skip-build',
            'Whether to skip building or not.') {|value|
    Options[:skip_build] = value
  }
  parser.on('--skip-test',
            'Whether to skip testing or not.') {|value|
    Options[:skip_test] = value
  }
  parser.on('--sdk=VALUE',
            '(OS X Only) SDK name to be passed to `xcrun`.'){|value|
    Options[:sdk] = value
    failed("Invalid SDK Name: #{sdk}") if sdk !~ /\A[\.0-9A-Z_a-z]+\Z/
  }
  parser.on('--clean',
            'Whether to clean up or not.') {|value|
    Options[:clean] = value
  }
            
  begin
    parser.parse!(ARGV)
  rescue  OptionParser::ParseError  => error
    failed(error.message + "\n" + parser.help)
  end
}

# Set SDK Name if it's nil
Options[:sdk] = Defaults[:sdk] if OS == :OS_X && Options[:sdk].nil?

# Check SDK Name
if OS == :OS_X && !system(%Q[xcrun --sdk #{Options[:sdk]} --show-sdk-path >/dev/null 2>&1])
  if $?.exitstatus == 127
    failed("'xcrun' does not exist.")
    else
    failed("Invalid SDK Name: #{Options[:sdk]}")
  end
end

# Build Directory
def exit_if_path_is_not_directory(path)
  failed(%Q["#{path.to_s}" is Not Directory]) if path.exist? && !path.directory?
end
Options[:build_directory] = Defaults[:build_directory] if Options[:build_directory].nil?
Options[:build_directory] = Options[:build_directory].expand_path if Options[:build_directory].relative?
exit_if_path_is_not_directory(Options[:build_directory])
Options[:build_directory] += Options[:sdk] if !Options[:sdk].nil?
exit_if_path_is_not_directory(Options[:build_directory])
FileUtils.rm_r(Options[:build_directory].to_s) if Options[:clean]
FileUtils.mkdir_p(Options[:build_directory].to_s)

# Set Options from defaults
cache_txt = Options[:build_directory] + 'build_options-cache.txt'
saved_defaults = nil
if cache_txt.exist?
  saved_defaults = JSON.parse(File.read(cache_txt.to_s), {:symbolize_names => true})
  saved_defaults.each_key{|key|
    if key == :build_directory || key == :swiftc || key == :prefix
      saved_defaults[key] = Pathname(saved_defaults[key])
    end
  }
end
Defaults.each_pair{|key, value|
  next if key == :sdk || key == :build_directory || key == :clean
  if Options[key].nil?
    if !saved_defaults.nil? && !saved_defaults[key].nil?
      Options[key] = saved_defaults[key]
    else
      Options[key] = Defaults[key]
    end
  end
}
File.write(cache_txt.to_s, JSON.dump(Options))

# Determine Swift Path
if !system(%Q[which #{Options[:swiftc].escaped} >/dev/null])
  failed("`swiftc` is not found.")
end
swiftc_command =
  (OS == :OS_X) ? "xcrun --sdk #{Options[:sdk]} #{Options[:swiftc].escaped}"
  : Options[:swiftc].escaped

# Detect Swift Version
swift_version = %x[#{swiftc_command} --version]
if swift_version =~ /^(?:Apple\s+)?Swift\s+version\s+(\d+)((?:\.\d+)*)\s+/
  swift_version = Regexp.last_match(1) + Regexp.last_match(2)
  if (swift_version.split('.').map(&:to_i) <=> RequiredSwiftVersion.split('.').map(&:to_i)) < 0
    failed("The minimum required version of Swift is #{RequiredSwiftVersion}")
  end
else
  failed("Cannot detect the version of Swift: #{swift_version}")
end

# Print Options
puts("Options:")
puts(%Q[  Swift Compiler: #{Options[:swiftc].to_s}])
puts(%Q[  Swift Version: #{swift_version}])
puts(%Q[  The Build Directory: "#{Options[:build_directory].to_s}"])
if Options[:install]
  puts(%Q[  The Installation Prefix: "#{Options[:prefix].to_s}"])
else
  puts(%Q[  No products will be installed.])
end
puts(%Q[  Skip building: #{Options[:skip_build] ? "Yes" : "No"}])
puts(%Q[  Skip testing: #{Options[:skip_test] ? "Yes" : "No"}])

# Create directories
build_include_directory = Options[:build_directory] + 'include'
build_lib_directory = Options[:build_directory] + 'lib'
if !Options[:skip_build] || !Options[:skip_test]
  FileUtils.mkdir_p(Options[:build_directory].to_s) if !File.exists?(Options[:build_directory])
  FileUtils.mkdir_p(build_include_directory.to_s) if !File.exists?(build_include_directory)
  FileUtils.mkdir_p(build_lib_directory.to_s) if !File.exists?(build_lib_directory)
end

# Let's Start!
def try_exec(command)
  puts("  Execute: #{command}")
  if !system(command)
    failed("Command exited with status #{$?.exitstatus}")
  end
end

## BUILD
if !Options[:skip_build]
  puts("===== BUILD =====")
  
  library_sources = all_files(LibrarySources, SourcesDirectory)
  
  create_module =
    "#{swiftc_command} " +
    library_sources.map{|file| file.escaped}.join(' ') + ' ' +
    "-module-name #{ModuleName} " +
    "-module-link-name #{ModuleLinkName} " +
    "-emit-module-path #{build_include_directory.escaped}/#{ModuleName}.swiftmodule "
  try_exec(create_module)
  
  build_library =
    "#{swiftc_command} " +
    library_sources.map{|file| file.escaped}.join(' ') + ' ' +
    "-module-name #{ModuleName} " +
    "-emit-library " +
    "-o#{build_lib_directory.escaped}/#{SharedLibraryPrefix}#{ModuleLinkName}#{SharedLibrarySuffix}"
  try_exec(build_library)
  
  puts("...DONE")
end

## TEST
if !Options[:skip_test]
  puts("===== TEST =====")
  
  test_executable = Options[:build_directory] + 'test'
  test_sources = all_files(TestSources, SourcesDirectory)
  
  if !test_executable.exist?
    puts("Start building an executable")
    build_test =
      "#{swiftc_command} " +
      test_sources.map{|file| file.escaped}.join(' ') + ' ' +
      "-o#{test_executable.escaped} " +
      "-I#{build_include_directory.escaped} " +
      "-L#{build_lib_directory.escaped}"
    try_exec(build_test)
  end
  
  puts("Start tests")
  if !system(%Q[LD_LIBRARY_PATH=#{build_lib_directory.escaped} #{test_executable.escaped}])
    failed("TEST FAILED.")
  end
  
  puts("..SUCCESSFUL")
end

## INSTALL
if Options[:install]
  puts("===== INSTALL =====")
  
  include_directory = Options[:prefix] + 'include'
  lib_directory = Options[:prefix] + 'lib'
  
  FileUtils.mkdir_p(include_directory.to_s) if !File.exists?(include_directory)
  FileUtils.mkdir_p(lib_directory.to_s) if !File.exists?(lib_directory)

  begin
    FileUtils.copy_entry(build_include_directory.to_s,
                         include_directory.to_s)
    FileUtils.copy_entry(build_lib_directory.to_s,
                         lib_directory.to_s)
  rescue
   failed("Installation Failed.")
  end
  
  puts("...DONE.")
end
