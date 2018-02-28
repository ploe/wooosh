#! env $(which ruby)

class WoooshGetter

require 'fileutils'
require 'net/ftp'

attr_accessor :arch, :dest, :ftp, :options, :snapshots, :version

def initialize(options)
	@arch = %x[uname -m].chomp
	@version = %x[uname -r].chomp

	@options = options.clone

	login

	# build a list of the snapshots, set them to false so they're not 
	# included by default.
	@snapshots = {}
	@ftp.nlst.each do |snapshot|
		if snapshot.match(/\.txz$/) then
			snapshot.gsub!(/\.txz$/, "")
			@snapshots[snapshot] = false
		end
	end

	close

	# set all the included snapshots to true
	@options[:include].each do |snapshot|
		if @snapshots[snapshot] == false then
			@snapshots[snapshot] = true
		else
			$stderr.puts "'#{ snapshot }' isn't available."
		end
	end

	# we always want the base image downloading, that's kinda the point of this!
	@snapshots['base'] = true

	# Make sure the path to the dest exists
	@dest = @options[:dest]
	FileUtils.mkdir_p(@dest)


	self
end

def login
	@ftp = Net::FTP.new("ftp.freebsd.org")
	@ftp.login
	@ftp.chdir("pub/FreeBSD/snapshots/#{ @arch }/#{ @version }")
end

def close
	@ftp.close
end

def cp_resolv
	etc_path = "#{ @dest }/etc"
	resolv_path = "#{ etc_path }/resolv.conf"
	FileUtils.mkdir_p(resolv_path)
	puts "Copying '/etc/resolv.conf' to '#{ etc_path  }'"
	FileUtils.cp("/etc/resolv.conf", "#{ resolv_path }")

	self
end

def download
	login

	@snapshots.keys.each do |snapshot|
		if @snapshots[snapshot] then
			file = snapshot + ".txz"
			path = "#{ @dest }/#{ file }"
			puts "wooosh: downloading '#{ snapshot }' to '#{ path }'"
			ftp.getbinaryfile(file, "#{ path }")
		end
	end

	close

	self
end

def list
	return @snapshots.keys
end

def untar
	@snapshots.keys.each do |snapshot|
		if @snapshots[snapshot] then
			file ="#{ @dest }/#{ snapshot }.txz"
			puts "wooosh: extracting '#{ file }'"
			system("tar -xf #{ file } -C #{ @dest }")
		end
	end

	self
end

def clean
	@snapshots.keys.each do |snapshot|
		if @snapshots[snapshot] then
			path = "#{ @dest }/#{ snapshot }.txz"
			puts "wooosh: removing '#{ path }'"
			FileUtils.rm_f(path)
		end
	end

	self
end

end
