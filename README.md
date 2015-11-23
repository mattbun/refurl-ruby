Refurl (that's probably the final name for it)
======

You know how url shorteners and image hosting websites have cool URLs like this one? http://i.imgur.com/nuR4V.gif

What if you could make cool links like that that point to your own files? If a friend wants something off of your computer, you could just send them a simple link like "yourdomain.com/nuR4V" and they could download it directly from your computer at home!

Well, that's what refurl is. I'm still working on it, so it's a little rough around the edges but it should be fine to expose it to the internet.

##Getting Started##
1. Install dependencies, `gem install sinatra filesize`
2. Update config.rb with the path to the files you want to share
3. Start it by running `./that.rb -o 0.0.0.0`
4. Start creating links by pointing your browser to `localhost:4567/refurl/create`

##Screenshots##
You can create links with expiration dates and a certain number of downloads before the link stops working
![create screenshot](https://raw.githubusercontent.com/qiquen/that/master/screenshots/screenshot_create.png)

You can see all of the links that are active
![manage screenshot](https://raw.githubusercontent.com/qiquen/that/master/screenshots/screenshot_manage.png)

And finally this is what it looks like when someone accesses one of your links
![download screenshot](https://raw.githubusercontent.com/qiquen/that/master/screenshots/screenshot_downloadfile.png)

You can make links to folders too!
![download screenshot](https://raw.githubusercontent.com/qiquen/that/master/screenshots/screenshot_downloaddir.png)
