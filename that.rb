#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'filesize'
require 'json'
require_relative 'db'

db = DB.new
rootpath = "/media"

#get '/' do
#    erb :index
#end

def getAHash(db)
    # bubblebabble makes for some fun looking hashes
    require 'digest/bubblebabble'

    counter = 0
    hash = nil
    while (hash == nil || db.hasKey(hash))
        return "" if (counter == 10)
        hashes = (Digest::SHA256.bubblebabble Time.now.to_s + counter.to_s).split("-")
        hash = hashes[rand(hashes.length - 1)]
        counter += 1
    end

    return hash
end

get '/manage' do
    @hash = getAHash(db)
    erb :manage
end

post '/manage/add' do
    fullpath = rootpath + params["path"]
    size = File.size(fullpath)
    size = Filesize.from("#{size} B").pretty
    db.add(params["key"], Record.new(params["key"], params["name"], fullpath, size))
end

get '/:key/download' do |n|
    record = db.get(n)
    filename = File.basename(record.path)
    send_file record.path, :filename => filename, :type => 'Application/octet-stream'
end


get '/api/ls' do
    path = params['path']
    fullpath = rootpath
    if (path != nil)
        fullpath += path
    end

    isDir = File.directory?(fullpath)
    answer = {:success => true, :isdir => isDir, :path => path}

    if (isDir)
        answer[:listing] = Dir.entries(fullpath).sort
    end

    return JSON.generate(answer)
end

get '/api/hash' do 
    getAHash(db)
end



get '/list' do
    path = params['path']
    fullpath = rootpath
    if (path != nil)
        fullpath += "/" + path
    else 
        path = ""
    end

    @path = path
    erb :list
end   

get '/:key' do |n|
    record = db.get(n)
    if (!record) then
        halt 404
    end

    @key = n
    @name = record.name
    @size = record.size
    @path = record.path
    erb :download
end

post '/jqueryfiletree-connector' do
    dir = params["dir"].to_s

    #TODO Check that dir is in our root
    #

    fullpath = rootpath
    if (dir != nil)
        fullpath += dir
    end

    filelist = []
    if (File.directory?(fullpath))
        filelist = Dir.entries(fullpath).sort
    end
    
    response = "<ul class=\"jqueryFileTree\" style=\"display: none;\">"

    filelist.each{
        |item|
        next if (item == "." || item == "..")

        if (File.directory?(fullpath + "/" + item))
            response += "<li class=\"directory collapsed\"><a href=\"#\" rel=\"#{dir + item}/\">#{item}</a></li>";
        else
            ext = File.extname(item)[1..-1]
            response += "<li class=\"file ext_#{ext}\"><a href=\"#\" rel=\"#{dir + item}\">#{item}</a></li>"
        end
    }

    response += "</ul>"
    return response
end
        
