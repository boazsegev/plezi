module Plezi
	module Builder

		GEM_ROOT = ::File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

		def self.write_files files, parent = "."
			if files.is_a? Hash
				files.each do |k, v|
					if v.is_a? Hash
						begin
							Dir.mkdir k
							puts "    created #{parent}/#{k}".green
						rescue Exception => e
							puts "    exists #{parent}/#{k}".red
						end
						Dir.chdir k
						write_files v, (parent + "/" + k)
						Dir.chdir ".."
					elsif v.is_a? String
						if ::File.exists? k
							if false #%w{Gemfile rakefile.rb}.include? k
								# old = IO.read k
								# old = (old.lines.map {|l| "\##{l}"}).join
								# IO.write k, "#####################\n#\n# OLD DATA COMMENTED OUT - PLEASE REVIEW\n#\n##{old}\n#{v}"
								# puts "    #{parent}/#{k} WAS OVERWRITTEN, old data was preserved by comenting it out.".pink
								# puts "    #{parent}/#{k} PLEASE REVIEW.".pink
								# @end_comments << "#{parent}/#{k} WAS OVERWRITTEN, old data was preserved by comenting it out. PLEASE REVIEW."
							else
								puts "    EXISTS(!) #{parent}/#{k}".red
							end
						else
							IO.write k, v
							puts "    wrote #{parent}/#{k}".yellow
						end
					end
				end
			end
		end
	end

end
