class DB
    def initialize()
        if (File.exist?("./db.yaml"))
            @data = YAML::load_file("./db.yaml")
        else 
            @data = {}
        end
    end

    def add(rootpath, key, name, path)
        return "Key can't be blank" if (key.to_s == "")
        return "Key is too long" if (key.length > 1024)
        
        return "Name can't be blank" if (name.to_s == "")
        return "Name is too long" if (name.length > 1024)
        
        return "Path can't be blank" if (path.to_s == "")
        fullpath = rootpath + path
        return "Path is too long" if (fullpath.length > 4096) #http://unix.stackexchange.com/questions/32795
        return "File does not exist" if (!File.exist?(fullpath))
        return "Path is not in root directory" unless (File.expand_path(fullpath).start_with?(File.expand_path(rootpath)))

        record = Record.new(key, name, fullpath)

        @data[key] = record
        saveDB()

        return nil
    end

    def saveDB()
        File.open('./db.yaml', 'w') {|f| f.write @data.to_yaml }
        return
    end

    def get(key)
        return @data[key]
    end

    def hasKey(key)
        return @data.has_key?(key)
    end

    def getKeys()
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
        result = []

        @data.each do |key, value|
            result.push({:key => key, :name => value.name, :path => value.path})
        end

        return JSON.generate(result)
    end



end

class Record
    attr_reader :name
    attr_reader :path

    def initialize(key, name, path)
        @key = key
        @name = name
        @path = path
    end

end
