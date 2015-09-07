#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'filesize'
require 'json'
require_relative 'db'
require_relative 'config'

db = DB.new
rootpath = ROOT_PATH.chomp("/")
domain = DOMAIN.chomp("/")

#get '/' do
#    erb :index
#end

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [AUTH_USER, AUTH_PASS]
  end
end


get '/that-add' do
    protected!
    @hash = getAHash(db)
    erb :add
end

get '/that-manage' do
    protected!
    @tablebody = ""
    keys = db.getKeys
    keys.each do |key|
        entry = db.get(key)
        @tablebody += "<tr>\n"
        @tablebody += "<td>" + entry.name.to_s + "</td>\n"
        @tablebody += "<td><a href='" + key.to_s + "'>" + key.to_s + "</a></td>\n"
        @tablebody += "<td>" + entry.path.to_s + "</td>\n"
        @tablebody += "<td><button type='button' class='btn btn-xs btn-danger' onclick='deleteLink(\"" + key.to_s + "\")'>Delete</button></td>\n"
        @tablebody += "</tr>\n"
    end

    erb :manage
end

# API
post '/api/add' do
    protected!
    error_message = db.add(rootpath, params["key"], params["name"], params["path"])

    if (error_message != nil)
        result = {:status => "error", :key => params["key"], :error => error_message}
    else
        result = {:status => "ok", :key => params["key"], :url => domain + "/" + params["key"]}
    end

    return JSON.generate(result)
end

get '/api/ls' do
    protected!
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
    protected!
    getAHash(db)
end

delete '/api/delete/:key' do |key|
    protected!
    db.delete(key)
    return 200
end

post '/jqueryfiletree-connector' do
    protected!
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

    filelist.each {
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

get '/:key/download' do |n|
    record = db.get(n)
    halt 404 if (!record)
    filename = File.basename(record.path)
    send_file record.path, :filename => filename, :type => 'Application/octet-stream'
end

get '/:key' do |n|
    record = db.get(n)
    halt 404 if (!record)

    @key = n
    @name = record.name
    @size = record.size
    @path = record.path
    erb :download
end


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
