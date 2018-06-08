#! env $(which ruby)

require 'optparse'

require './WoooshGetter.rb'

options = {
	:dest => './',
	:include => [],
	:freebsd => %x[uname -r].chomp,
}

OptionParser.new do |opts|
	opts.banner = "usage: wooosh get -i [snapshot] "

	opts.on("-d dest", "--dest dest", "Path to the destination directory for the image.") do |dest|
		options[:dest] = dest
	end

	opts.on("-f n", "--freebsd", "The FreeBSD version to copy. Defaults to the version of the host.") do |freebsd|
		options[:freebsd] = freebsd
	end

	opts.on("-i n", "--include n", "Includes 'snapshot' specified by name.") do |snapshot|
		options[:include].push(snapshot)
	end

	opts.on("-l", "--list", "Get a list of the snapshots to include. 'base' is always included by default.") do |list|
		options[:list] = list
	end


end.parse!

getter = WoooshGetter.new(options)

if options[:list] then
	getter.list.each do |snapshot|
		puts snapshot
	end
else
	getter.download.untar.clean.cp_resolv.update
end
