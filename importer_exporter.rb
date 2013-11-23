require 'CSV'
require 'json'

class Stock
	@@array = Array.new()
	def initialize(hash_stock_attr_value)
		if rulesCheck?(hash_stock_attr_value)				#dynamically constructing stock object assigning parameters set in config 
		 	hash_stock_attr_value.each{|attr,value|			#as instance variables and setting them to the value obtained from the data 
				self.class.send(:attr_accessor, attr)		#file after checking if rule match
				instance_variable_set("@#{attr}", value)
			}
		else
			raise "Rule Break at line #{@@array.length if !@@array.nil?}"
			#placeholder: to add what to do when rule mismatch occurs
		end
		@@array << self							# add stock object obtained for each row to the class variable @@array 
	end
	
	def self.to_hash()
		array_hash_objs = Array.new()		
		@@array.each { |obj|
			hash_stock_obj = Hash.new()
			array_instance_variables = obj.instance_variables
			array_instance_variables.each {|var|
				hash_stock_obj[var.to_s.sub("@","")] = obj.instance_variable_get var
			}
			array_hash_objs << hash_stock_obj.compare_by_identity
		}
		return array_hash_objs
	end
	
	def rulesCheck?(hash_stock_obj)													#assign rules to check each record of the data 
		rule_satisfied = true
		if hash_stock_obj["price_type"] == "open" and hash_stock_obj["cost"]
			rule_satisfied = false
		#placeholder: to add rules in future
		end
		return rule_satisfied
	end
	
end

module FormatType
	def self.getIOType(file)
		file_type = file.downcase
		if file_type.include? ".csv"										#dynamically sets the file type
			return "csv" 
		elsif file_type.include? ".json"
			return "json"
		#placeholder: to add formats in the future
		else
			raise "add input type to method"
		end
	end	
	def self.read(file_input,hash_model)
		case getIOType(file_input)												#if input file is csv, each line from the csv is read into  
			when "csv"															#into the model hash generated from the config settings 
				CSV.foreach(file_input,{:headers => true}) { |row|				# after checking for parameter matches
					hash_results = Hash.new()
					hash_row = row.to_hash
					hash_model.each{|attr,type|
						if type == "string"
							hash_results[attr] = hash_row.select {|key, value| key == attr or (key.include? attr and hash_row[attr]==hash_row[hash_row])}.first.last
						elsif type.is_a? Array
							array_values = Array.new()
							hash_row.each {|key, value| 
								hash_type = Hash.new()
								type.each{|spec|
									if key.include? attr and key.include? spec and value!=nil
										number_of_modifier = key.match(/([\d]+)/)
										spec_number = number_of_modifier.captures[0]
										if array_values[spec_number.to_i - 1] == nil
											hash_type[spec] = value
											array_values[spec_number.to_i-1] = hash_type
										else 
											array_values[spec_number.to_i-1][spec] = value
										end
										
									end
								}
								hash_results[attr] = array_values
							}
						#placeholder: to add if hash is included in the parameters
						end
					}	
					yield hash_results
				}
			when "json"												#if input file is csv, each line from the csv is read into  
				data = JSON.parse(File.read(file_input))			#into the model hash generated from the config
				data.each { |obj|			 						#settings after checking for parameter matches
					if obj.size == hash_model.size and (obj.keys - hash_model.keys).empty?()
						obj.each{|key,value|
									raise "Mismatch between model specified in config and input file" if (hash_model[key] != "string" and value.is_a? String) or (!hash_model[key].is_a? Array and value.is_a? Array)
						}
						yield obj
					end
				}
		#placeholder: to accept other formats in future
		end
	end

	def self.write(file_output, obj)
		case getIOType(file_output)
			when "csv"
				column_names = flatten_hash_to_array(obj.to_hash.first).keys
				s=CSV.generate do |csv|
					csv << column_names
					obj.to_hash.each do |x|
						csv << flatten_hash_to_array(x).values
						
					end
				end
				File.open(file_output,"w") do |f|
					f.write(s)
				end
			when "json"
				File.open(file_output,"w") do |f|
					f.write(JSON.pretty_generate(obj.to_hash))
				end
		end
	end
	def self.flatten_hash_to_array(obj,parent_prefix = nil)
		res = {}

		obj.each_with_index do |elem, i|
			if elem.is_a?(Array)							#recursively flattens the array of hashes in the case of modifiers
				k, v = elem									# assigning numbers to each pain of hash	
			else
				k, v = i+1, elem
			end
			
			key = parent_prefix ? "#{parent_prefix}_#{k}" : k # assign key name for result hash
			if v.is_a? Array or v.is_a? Hash
				res.merge!(flatten_hash_to_array(v, key)) # recursive call to flatten child elements
			else
				res[key] = v
			end
		end
		return res
  end
end


module ConfigSetting
	def self.getConfig()
		model_or_format_flag = ""
		file_export = ""
		file_import = ""
		model_str_array = Array.new()
		
		hash_config_settings = Hash.new()
		IO.foreach("D:\\Career\\ShopKeepPOS Programming Exercise\\ConfigFile.txt"){|line|
			str_line = line.chomp
			model_or_format_flag = "M" if str_line.downcase.include? "model"
			model_or_format_flag = "E" if str_line.downcase == "export"
			model_or_format_flag = "I" if str_line.downcase == "import"
			#placeholder: to get config data from file in class of future modifications required in the Configuration.
			if model_or_format_flag == "M" and str_line.downcase!="model" and str_line.match(/^\w+/)
				model_str_array << str_line.downcase
			elsif model_or_format_flag == "E" and str_line.downcase!="export" and str_line.match(/^\w+/)
				file_export = str_line
			elsif model_or_format_flag == "I" and str_line.downcase!="import" and str_line.match(/^\w+/)
				file_import = str_line 				
			end			
		}
		if model_str_array.nil? or file_export.nil? or file_import.nil?
			raise "Error in Config File"
		else
			hash_config_settings["model"] = getModel(model_str_array) 					  
			hash_config_settings["file_export"] = file_export
			hash_config_settings["file_import"] = file_import
			return hash_config_settings
		end
				
	end

	def self.getModel(model_str_array)
		model = Hash.new(0)
		
		model_str_array.each{|str_line|
			arr_line_split = str_line.split(/\s*\t*\:\:\s*\t*/)
			if arr_line_split[1] !~ /array/
				model[arr_line_split[0]] = arr_line_split[1]			#get model structure as set in the Config file into hash
			else
				model_attr_type = arr_line_split[1].match(/([\w]*),([\w]*)/)	#for parameters like modifier, the model structure is 
				model[arr_line_split[0]] = model_attr_type.captures.to_a()		# an array of sub categories assigned to the modifier key
			end																	# e.g. "modifier"=>["name", "price"]}
		}
		return model
	end
end

module StockImpExp
	@config = ConfigSetting.getConfig()		#hash containing the Config settings
	def self.import
		FormatType.read(@config["file_export"],@config["model"]){|hash_result| Stock.new(hash_result) }
		FormatType.write(@config["file_import"],Stock)
	end
	def self.export
		FormatType.read(@config["file_import"],@config["model"]){|hash_result| Stock.new(hash_result) }
		FormatType.write(@config["file_export"],Stock)
	end
end


StockImpExp.import				#choose importer or exporter based on files set Config
StockImpExp.export				# Imports into the Import File
								# Exports into the Export file



