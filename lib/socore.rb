#!/usr/bin/env ruby

class Socore
  def update_cookbook
    # check if cookbook exists, if not check it out

    # if so do a git pull (with force?)
  end


  def read_config(file_name)
    $cookbooks = {}
    config_file = file_name
    File.readlines(File.join(File.dirname(__FILE__), config_file)).each do |line|
      line.gsub!("\n", "")
      regex_result = line.match(/(\w+)?cookbook '([-\w]+)', :git => '([^']*)'/)
      $cookbooks[regex_result[2].to_s] = regex_result[3].to_s
    end
    $cookbooks
  end

  def read_lockfile(file_name)
    lock_file = file_name
    $locks = {}
    File.readlines(File.join(File.dirname(__FILE__), lock_file)).each do |line|
      line.gsub!("\n", "")
      regex_result = line.match(/(\w+)?cookbook '([-\w]+)', :git_sha => '([^']*)', :dir_hash => '([^']*)'/)
      $locks[regex_result[2].to_s] = { :git_sha => regex_result[3].to_s, :dir_hash => regex_result[4].to_s }
    end
    $locks
  end

  def get_dir_hashes(cookbooks)
    require 'find'
    require 'digest/md5'

    my_cookbooks = cookbooks
    $hashes = {}
    my_cookbooks.each do |cookbook, git|
      # Find all directories in cookbook folder and add to an array
      $cookbook_dir = File.join("../", cookbook)
      ls_glob = ""
      $directories = []
      Find.find($cookbook_dir) { |e| $directories << e if File.directory?(e) }
      # sort the array
      $directories.sort!
      # run an ls on each of those directories and append the output to a string
      $directories.each do |dir|
        ls_glob += `ls -altr #{dir}`
      end
      # get the hash of that string
      $hashes[cookbook.to_s] = Digest::MD5.hexdigest ls_glob
      # return the hash
      return $hashes
    end
  end

  def install_cookbook

  end

  def update_lockfile

  end

  def socore
    debug = true
    cookbooks = read_config("socore.conf")
    locks = read_lockfile("socore.lock")
    hashes = get_dir_hashes(cookbooks)
    $updated_cookbooks = {}

    if debug
      locks.each do |cookbook, data|
        puts "Lock: #{cookbook}, Git SHA: #{data[:git_sha]}, Dir Hash: #{data[:dir_hash]}"
      end
      hashes.each do |cookbook, hash|
        puts "Hash: #{cookbook}, Value: #{hash}"
      end
    end

    cookbooks.each do |name, uri|
      if debug then puts "Cookbook: #{name}, URI: #{uri}" end

      # Check lockfile for currently pulled hash
      git_lock_hash, dir_lock_hash = locks[name.to_s]
      git_cur_hash, dir_cur_hash = hashes[name.to_s]

      if git_lock_hash.nil? || git_cur_hash.nil? || dir_lock_hash.nil? || dir_cur_hash.nil?
        # if no hash - have git download the repository over the existing one
        puts "#{name} has no metadata, installing a fresh copy..."
        install_cookbook(name, uri)
        update_lockfile(name, git_cur_hash, dir_cur_hash)
        $updated_cookbooks[name] = {"git_sha" => git_cur_hash.to_s, "dir_hash" => dir_cur_hash.to_s}
          # add new sha and git repo name to changed hash
      elsif git_lock_hash == git_cur_hash && dir_lock_hash == dir_cur_hash
        # if hash - compare to git.has file in dir & compare directories hash to git hash to make sure it has not changed locally either
        # if hashes are the same - do nothing
        puts "#{name} is up to date"
      else
        # else - have git download the repo, create the git.hash file, write the git hash and directory sha to the pull.lock
        puts "#{name} needs an update..."
        install_cookbook(name, uri)
        update_lockfile(name, git_cur_hash, dir_cur_hash)
        $updated_cookbooks[name] = {"git_hash" => git_cur_hash.to_s, "dir_hash" => dir_cur_hash.to_s}
          # add new sha and git repo name to changed hash
      end

      if !$updated_cookbooks.empty

      end
      # if changed - commit all changes and push using changed hash as comment
    end
    puts "Done processing cookbooks config..."

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

