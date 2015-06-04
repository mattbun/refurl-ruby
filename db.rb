class DB
    def initialize()
        if (File.exist?("./db.yaml"))
            @data = YAML::load_file("./db.yaml")
        else 
            @data = {}
        end

    end

    def add(key, value)
        @data[key] = value
        saveDB()
    end

    def saveDB()
        File.open('./db.yaml', 'w') {|f| f.write @data.to_yaml }
    end

    def get(key)
        return @data[key]
    end

    def print()
        puts @data
    end

end

class Record
    attr_reader :name
    attr_reader :path
    attr_reader :size

    def initialize(key, name, path, size)
        @key = key
        @name = name
        @path = path
        @size = size
    end

end
