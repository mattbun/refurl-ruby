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

get '/manage' do
    erb :manage
end

post '/manage/add' do
    fullpath = rootpath + params["path"]
    size = File.size(fullpath)
    size = Filesize.from("#{size} B").pretty
    db.add(params["key"], Record.new(params["key"], params["name"], fullpath, size))
end

get '/download/:key' do |n|
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
    erb :download
end
