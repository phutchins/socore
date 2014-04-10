#!/usr/bin/env ruby

class Socore
  $debug = true
  def read_config(file_name)
    $cookbooks = {}
    config_file = file_name
    puts "Config: #{File.join(File.dirname(__FILE__), config_file)}"
    File.readlines(File.join(File.dirname(__FILE__), config_file)).each do |line|
      #puts "DEBUG - read_config - Line: #{line}" if $debug
      line.gsub!("\n", "")
      regex_result = line.match(/(\w+)?cookbook '([-\w]+)', :git => '([^']*)'/)
      #puts "DEBUG - read_config - regex[2]: #{regex_result[2].to_s}, regex[3]: #{regex_result[3].to_s}" if $debug
      $cookbooks[regex_result[2].to_s] = regex_result[3].to_s
    end
    $cookbooks.each do |cookbook, uri|
      #puts "DEBUG - Found cookbook: #{cookbook} URI: #{uri}"
    end unless $cookbooks.nil? if $debug
    $cookbooks
  end

  def read_lockfile(file_name)
    lock_file = file_name
    $locks = {}
    begin
      File.readlines(File.join(File.dirname(__FILE__), lock_file)).each do |line|
        line.gsub!("\n", "")
        regex_result = line.match(/(\w+)?cookbook '([-\w]+)', :git_sha => '([^']*)', :dir_hash => '([^']*)'/)
        $locks[regex_result[2].to_s] = { :git_sha => regex_result[3].to_s, :dir_hash => regex_result[4].to_s }
      end
    rescue
      puts "No lockfile found"
    end
    $locks
  end

  def get_dir_hash(cookbook)
    require 'find'
    require 'digest/md5'

    #puts "DEBUG - get_dir_hash - cookbooks: #{cookbooks.inspect}" if $debug
    #puts "  - get_dir_hash -" if $debug
    # Find all directories in cookbook folder and add to an array
    pwd = `pwd`.chomp
    #puts "DEBUG - Getting hash for '#{cookbook}' cookbook" if $debug

    $cookbook_dir = File.join(pwd, cookbook).to_s
    $directories = []
    puts "DEBUG - get_dir_hash - Looking for all files in #{$cookbook_dir}" if $debug
    begin
      Find.find($cookbook_dir) { |e| $directories << e if File.directory?(e) }
      # sort the array
      $directories.sort!
      ls_glob = ""
      # run an ls on each of those directories and append the output to a string
      $directories.each do |dir|
        ls_glob += `ls -altr #{dir}`
      end
      puts "DEBUG - get_dir_hash - [#{cookbook}] ls_glob.length: #{ls_glob.length}" if $debug
      # get the hash of that string
      $cookbook_hash = Digest::MD5.hexdigest ls_glob
      # return the hash
    rescue Exception => e
      puts "No cookbooks found."
      puts "EXCEPTION: #{e.backtrace}" if $debug
    end
    puts "DEBUG - get_dir_hash - returning $hashes: #{$cookbook_hash.inspect}" if $debug
    return $cookbook_hash
  end

  def install_cookbook(name, uri)
    `rm -rf ./#{name} && git clone #{uri} #{name}`
    git_sha = `cd ./#{name} && git rev-parse HEAD`.chomp
    git_sha
  end

  def get_git_sha(name)
    git_sha = `cd ./#{name} && git rev-parse HEAD`.chomp
    git_sha
  end

  def update_lockfile(lock_file, name, cur_git_sha, cur_dir_hash)
    locks = read_lockfile(lock_file)
    puts "  - READ LOCKFILE - " if $debug
    locks.each do |lock|
      puts "  - LOCK: #{lock.inspect}"
    end if $debug
    locks[name.to_s] = { :git_sha => cur_git_sha.to_s, :dir_hash => cur_dir_hash.to_s }
    # write locks to file converting to locks format
    puts "update_lockfile - LockFile: #{lock_file}" if $debug

    file = File.open(File.join(File.dirname(__FILE__), lock_file), 'w')
    file.truncate(file.size)
    locks.each do |cookbook, data|
      file.write("cookbook '#{cookbook}', :git_sha => '#{data[:git_sha]}', :dir_hash => '#{data[:dir_hash]}'\n")
    end
    file.close()
  end

  def socore
    lock_file = "socore.lock"
    config_file = "socore.conf"
    cookbooks = read_config(config_file)
    locks = read_lockfile(lock_file)
    $updated_cookbooks = {}

    if $debug
      locks.each do |cookbook, data|
        puts "DEBUG - Lock: #{cookbook}, Git SHA: #{data[:git_sha]}, Dir Hash: #{data[:dir_hash]}"
      end
      #hashes.each do |hash|
      #  puts "DEBUG - Hash: #{hash}"
      #end unless hashes.empty?
    end

    cookbooks.each do |name, uri|
      puts " - Processing cookbook '#{name}', URI: #{uri}"

      # Check lockfile for currently pulled hash
      lock_data = locks[name.to_s] || nil

      lock_git_sha = lock_data[:git_sha]
      cur_git_sha = get_git_sha(name)

      lock_dir_hash = lock_data[:dir_hash]
      cur_dir_hash = get_dir_hash(name) || nil
      puts "DEBUG - inspect cur_dir_hash: [#{name}] #{cur_dir_hash.inspect}" if $debug

      # get the SHA without checking out the cookbook here
      # cur_git_sha = install_cookbook(name, uri)

      puts "-DEBUG - lock_git_sha: #{lock_git_sha}" unless lock_git_sha.nil? if $debug
      puts "-DEBUG - cur_git_sha: #{cur_git_sha} " unless cur_git_sha.nil? if $debug
      puts "-DEBUG - lock_dir_hash: #{lock_dir_hash}" unless lock_dir_hash.nil? if $debug
      puts "-DEBUG - cur_dir_hash: #{cur_dir_hash}" unless cur_dir_hash.nil? if $debug
      if lock_git_sha.nil? || lock_dir_hash.nil?
        # No lock data is present so we should check out the repository, get the git sha and dir hash and write those to the lock file
        puts "#{name} has no metadata, installing a fresh copy..."
        # Clone the cookbook repository and get the current sha
        # FIX
        cur_dir_hash = get_dir_hash(name)
        cur_git_sha = install_cookbook(name, uri)
        # Need to update cur_git_sha and cur_dir_hash here
        puts "DEBUG - Updating LOCK file with - Cookbook: #{name}, cur_git_sha: #{cur_git_sha}, cur_dir_hash: #{cur_dir_hash}" if $debug
        update_lockfile(lock_file, name, cur_git_sha, cur_dir_hash)
        $updated_cookbooks[name] = {"git_sha" => cur_git_sha.to_s, "dir_hash" => cur_dir_hash.to_s}
          # add new sha and git repo name to changed hash
      elsif lock_git_sha == cur_git_sha && lock_dir_hash == cur_dir_hash
        # if hash - compare to git.has file in dir & compare directories hash to git hash to make sure it has not changed locally either
        # if hashes are the same - do nothing
        puts "#{name} is up to date"
      else
        # else - have git download the repo, create the git.hash file, write the git hash and directory sha to the pull.lock
        puts "#{name} needs an update..."
        cur_git_sha = install_cookbook(name, uri)
        cur_dir_hash = get_dir_hash(name)
        update_lockfile(lock_file, name, cur_git_sha, cur_dir_hash)
        $updated_cookbooks[name] = {"git_hash" => cur_git_sha.to_s, "dir_hash" => cur_dir_hash.to_s}
          # add new sha and git repo name to changed hash
      end

      if !$updated_cookbooks.empty?
        puts "Cookbooks upcated..."

      end
      # if changed - commit all changes and push using changed hash as comment
    end
    puts "Done..."

   # def run
   #   pull_output = `cd ../#{name} ; git pull`
   #   if debug then puts "DEBUG: #{pull_output}" end
   #   return_code = $?.to_i
   #   puts "Return Code: #{return_code}"
   #   if !return_code == 0
   #     checkout_output = `cd ../ ; git checkout #{uri}`
   #     if debug then puts "DEBUG: #{checkout_output}" end
   #     puts "Checked out #{name}"
   #   else
   #     puts "Updated #{name}"
   #   end
   # end
  end
end

