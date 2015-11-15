class DB
    def initialize()
        if (File.exist?("./db.yaml"))
            @data = YAML::load_file("./db.yaml")
        else 
            @data = {}
        end
    end

    def add(rootpath, key, name, path, expireDate, expireVisits)
        return "Key can't be blank" if (key.to_s == "")
        return "Key is too long" if (key.length > 1024)
        
        return "Name can't be blank" if (name.to_s == "")
        return "Name is too long" if (name.length > 1024)
        
        return "Path can't be blank" if (path.to_s == "")
        fullpath = rootpath + path
        return "Path is too long" if (fullpath.length > 4096) #http://unix.stackexchange.com/questions/32795
        return "File does not exist" if (!File.exist?(fullpath))
        return "Path is not in root directory" unless (File.expand_path(fullpath).start_with?(File.expand_path(rootpath)))

        record = Record.new(key, name, fullpath, expireDate, expireVisits)

        @data[key] = record
        saveDB()

        return nil
    end

    def saveDB()
        File.open('./db.yaml', 'w') {|f| f.write @data.to_yaml }
        return
    end

    def get(key)
		record = @data[key]
		
		if (!record.nil? && record.isExpired)
			delete(key);
			return nil;
		end

        return @data[key]
    end

    def hasKey(key)
		checkForExpired
        return @data.has_key?(key)
    end

    def getKeys()
		checkForExpired
        return @data.keys
    end

    def delete(key)
        @data.delete(key)
        saveDB()
        return
    end

    def print()
        puts @data
        return
    end

    def to_json
		checkForExpired
        result = []

        @data.each do |key, value|
            result.push({:key => key, :name => value.name, :path => value.path, :visits => value.visitCounter, :expireVisits => value.expireVisits, :expireDate => value.expireDate})
        end

        return JSON.generate(result)
    end

	def increment(key)
		record = @data[key]
		return if (record.nil?)

		record.incrementVisitCounter()
		
		if (record.isExpired)
			delete(key);
			return
		end

		saveDB()
	end

	def checkForExpired()
		@data.delete_if {|key, record| record.isExpired}
		saveDB()
	end
end

class Record
	attr_reader :key
    attr_reader :name
    attr_reader :path
	attr_reader :visitCounter
	attr_reader :expireDate
	attr_reader :expireVisits

    def initialize(key, name, path, expireDate, expireVisits)
        @key = key
        @name = name
        @path = path
		@visitCounter = 0
		@expireDate = expireDate
		@expireVisits = expireVisits
    end

	def incrementVisitCounter
		if (@visitCounter == nil)
			@visitCounter = 1
		else
			@visitCounter += 1
		end
	end

	def isExpired
		if (!@expireVisits.nil? && @visitCounter >= @expireVisits.to_i)
			return true
		end

		require 'time'
		if (!@expireDate.nil? && Time.now.utc > Time.iso8601(@expireDate))
			return true
		end

		return false
	end

end
