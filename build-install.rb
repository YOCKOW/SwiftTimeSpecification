#!/usr/bin/env ruby

=begin
build-install.rb
  © 2016-2017 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
=end

ModuleName = 'TimeSpecification'
ModuleVersion = "0.0.0"

# Requirements #####################################################################################
require 'fileutils'
require 'json'
require 'optparse'
require 'pathname'
require 'open3'
require 'shellwords'

# Constants ########################################################################################
OS = case RbConfig::CONFIG['host_os']
  when /darwin/i then :macOS
  when /linux/i then :Linux
  else :Other
end
SharedLibraryPrefix = 'lib'
SharedLibrarySuffix = (OS == :macOS) ? '.dylib' : '.so'
ModuleLinkName = 'Swift' + ModuleName
RootDirectory = Pathname(__FILE__).dirname.expand_path

## Default Values ##
Defaults = {
  :swift => Pathname('swift'),
  :build_directory => Pathname('./.build'),
  :install => false,
  :prefix => Pathname('/usr/local'),
  :debug => false,
  :skip_build => false,
  :skip_test => false,
  :clean => false
}
## Options ##
Options = {
  :swift => nil,
  :build_directory => nil,
  :install => nil,
  :prefix => nil,
  :debug => nil,
  :skip_build => nil,
  :skip_test => nil,
  :sdk => nil,
  :clean => nil
}
## Canceled ##
Canceled = {
  :debug => nil,
  :skip_build => nil,
  :skip_test => nil
}
### Qualifications ###
UnsavableOptions = [:build_directory, :sdk, :clean]
PathnameOptions = [:swift, :build_directory, :prefix]

# Functions ########################################################################################
## Error ##
def failed(message)
  $stderr.puts("!!ERROR!! #{message}")
  exit(false)
end

## Run Shell Script
def try_exec(command, indent = 0)
  puts(' ' * indent + "Execute: #{command}")
  Open3.popen3(command) {|stdin, stdout, stderr, wait_thread|
    stdin.close
    stdout.each {|line| $stdout.puts(' ' * indent * 2 + line) }
    stderr.each {|line| $stderr.puts(' ' * indent * 2 + line) }
    
    status = wait_thread.value.exitstatus
    failed("Command exited with status #{status}") if status != 0
  }
end

# Extends Class(es) ################################################################################
## Pathname ##
class Pathname
  def escaped(type = :shell)
    return Shellwords.shellescape(self.to_s) if type == :shell
    return self.to_s.gsub(/\$/, '$$').gsub(/\s/, '$\&') if type == :ninja
    return self.to_s
  end
  def exit_if_i_am_file
    failed("#{self.to_s} is not directory.") if self.exist? && !self.directory?
  end
end

# Parse Options ####################################################################################
OptionParser.new(__FILE__){|parser|
  parser.on('--swift=PATH',
            'Path to `swift` which you want to use.') {|path|
    path = Pathname(path)
    path += 'swift' if path.directory?
    Options[:swift] = Pathname(path)
  }
  parser.on('--build-dir=PATH', '--build-directory=PATH',
            'Name of the directory where the build products will be placed. ' +
            'Default: ' + Defaults[:build_directory].to_s) {|path|
    Options[:build_directory] = Pathname(path)
  }
  
  parser.on('--install',
            'Whether to install products or not.') {|value|
    Options[:install] = value
  }
  parser.on('--prefix=PATH', '--install-prefix=PATH',
            'The installation prefix. (Only used when `--install` is specified.) ' +
            'Default: ' + Defaults[:prefix].to_s) {|path|
    Options[:prefix] = Pathname(path)
    Options[:prefix]= Options[:prefix].expand_path if path =~ /\A~\//
    if !Options[:prefix].absolute?
      failed(%Q[The installation prefix must be absolute path.])
    end
    Options[:prefix].exit_if_i_am_file
    Options[:install] = true # install library if prefix is specified.
  }
  
  parser.on('--debug',
            'Debug builds') {|value|
    Options[:debug] = value
  }
  parser.on('--release',
            'Release builds; default is on') {|value|
    Canceled[:debug] = value
  }
  
  parser.on('--skip-build',
            'Whether to skip building or not.') {|value|
    Options[:skip_build] = value
  }
  parser.on('--do-build',
            'Cancel skipping building') {|value|
    Canceled[:skip_build] = value
  }
  
  parser.on('--skip-test',
            'Whether to skip testing or not.') {|value|
    Options[:skip_test] = value
  }
  parser.on('--do-test',
            'Cancel skipping testing') {|value|
    Canceled[:skip_test] = value
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

# Determine Options ################################################################################
UnsavableOptions.each{|key| Options[key] = Defaults[key] if Options[key].nil?}

## Build Directory
Options[:build_directory] = Defaults[:build_directory] if Options[:build_directory].nil?
Options[:build_directory] = RootDirectory + Options[:build_directory] if Options[:build_directory].relative?
Options[:build_directory].exit_if_i_am_file
FileUtils.rm_r(Options[:build_directory].to_s) if Options[:clean]
FileUtils.mkdir_p(Options[:build_directory].to_s)

## Save/Read Cache
cache_json = Options[:build_directory] + 'build_options-cache.json'
saved_defaults = nil
if cache_json.exist?
  saved_defaults = JSON.parse(File.read(cache_json.to_s), {:symbolize_names => true})
  saved_defaults.each_key{|key|
    saved_defaults[key] = Pathname(saved_defaults[key]) if PathnameOptions.include?(key)
  }
end
Defaults.each_pair{|key, value|
  next if UnsavableOptions.include?(key)
  if Options[key].nil?
    if !saved_defaults.nil? && !saved_defaults[key].nil?
      Options[key] = saved_defaults[key]
    else
      Options[key] = Defaults[key]
    end
  end
}
Canceled.each_pair{|key, value|
  Options[key] = false if !value.nil? && value
}
File.write(cache_json.to_s, JSON.dump(Options))
Options.each_pair {|key, value| Options[key] = Defaults[key] if value.nil? }

# Swift? ###########################################################################################
failed("#{Options[:swift]} is not found.") if !system(%Q[which #{Options[:swift].escaped()} >/dev/null])

# Build! ###########################################################################################
configuration = Options[:debug] ? 'debug' : 'release'

binPath = Pathname(%x[#{Options[:swift].escaped()} build --build-path #{Options[:build_directory].escaped()} --configuration #{configuration} --show-bin-path].chomp)
libFilename = Pathname(SharedLibraryPrefix + ModuleLinkName + SharedLibrarySuffix)
libPath = binPath + libFilename
moduleFilename = Pathname(ModuleName + '.swiftmodule')
modulePath = binPath + moduleFilename

# Build
if !Options[:skip_build]
  puts("[Start Building...]")
  try_exec(["#{Options[:swift].escaped()} build --build-path #{Options[:build_directory].escaped()}",
           "--configuration #{configuration}",
           "-Xswiftc -emit-library -Xswiftc -o#{libPath.escaped()}",
           "-Xswiftc -module-link-name -Xswiftc #{ModuleLinkName}",
           "-Xswiftc -module-name -Xswiftc #{ModuleName}",
           "-Xswiftc -emit-module-path -Xswiftc #{modulePath.escaped()}"].join(" "),
           2)
  puts()
end

# Test
if !Options[:skip_test]
  puts("[Start Testing...]")
  if !Options[:debug]
    $stderr.puts("** WARNING ** No tests will be executed unless debug mode is specified.")
  else
    try_exec(["#{Options[:swift].escaped()} test --build-path #{Options[:build_directory].escaped()}",
              "--configuration #{configuration}"].join(" "), 2)
  end
  puts()
end

# Install
if Options[:install]
  puts("[Installing...]")
  
  if Options[:debug]
    $stderr.puts("** WARNING ** DEBUG MODE. Products to be installed may not be optimized.\n")
  end

  if ModuleVersion =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)(?:\-(.+))?/
    majorVersion = $1
    minorVersion = $2
    patchVersion = $3
    prereleaseIdentifiers = $4
    
    suffixes = [
      ".#{majorVersion}.#{minorVersion}",
      ".#{majorVersion}",
      ""
    ]
    if prereleaseIdentifiers
      suffixes.unshift(".#{majorVersion}.#{minorVersion}.#{patchVersion}")
    end
    
    libInstallDirPath = Options[:prefix] + Pathname('lib')
    moduleInstallDirPath = Options[:prefix] + Pathname('include')
    originalLibFilename = Pathname(SharedLibraryPrefix + ModuleLinkName + SharedLibrarySuffix + '.' + ModuleVersion)
    originalModuleFilename = Pathname(ModuleName + '.swiftmodule' + '.' + ModuleVersion)
    originalLibInstallPath = libInstallDirPath + originalLibFilename
    originalModuleInstallPath = moduleInstallDirPath + originalModuleFilename
    
    try_exec("mkdir -p #{libInstallDirPath.escaped()}", 2)
    try_exec("rm -f #{originalLibInstallPath.escaped()}", 2)
    try_exec("cp -f #{libPath.escaped()} #{originalLibInstallPath.escaped()}", 2)
    try_exec("mkdir -p #{moduleInstallDirPath.escaped()}", 2)
    try_exec("rm -f #{originalModuleInstallPath.escaped()}", 2)
    try_exec("cp -f #{modulePath.escaped()} #{originalModuleInstallPath.escaped()}", 2)
    
    suffixes.each_with_index{|suffix, ii|
      sourceSuffix = (ii == 0) ? ('.' + ModuleVersion) : suffixes[ii - 1]
      
      libSourceFilename = Pathname(SharedLibraryPrefix + ModuleLinkName + SharedLibrarySuffix + sourceSuffix)
      moduleSourceFilename = Pathname(ModuleName + '.swiftmodule' + sourceSuffix)
      libDestFilename = Pathname(SharedLibraryPrefix + ModuleLinkName + SharedLibrarySuffix + suffix)
      moduleDestFilename = Pathname(ModuleName + '.swiftmodule' + suffix)
      
      libSourcePath = libInstallDirPath + libSourceFilename
      moduleSourcePath = moduleInstallDirPath + moduleSourceFilename
      libDestPath = libInstallDirPath + libDestFilename
      moduleDestPath = moduleInstallDirPath + moduleDestFilename
      
      try_exec("ln -fs #{libSourcePath.escaped()} #{libDestPath.escaped}", 2)
      try_exec("ln -fs #{moduleSourcePath.escaped()} #{moduleDestPath.escaped}", 2)
    }
  else
    $stderr.puts("Invalid Version")
  end
end

