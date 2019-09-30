#!/usr/bin/env ruby


########################
# Note: How to install nokogiri:
#  - sudo gem install nokogiri
# Documentation:
#  - http://nokogiri.org/Nokogiri/XML/Node.html
########################


require 'rubygems'
require 'nokogiri'
require 'open-uri'


########################
# Check arguments
########################
if ARGV.length != 1
  puts "Usage: completely_replace_pom_file_version.rb <tag_name>"
  exit 1
end

tag_name = ARGV[0]

########################
# Show program invoked
########################
welcome_msg = "Using Nokogiri to parse xml... "
puts welcome_msg
########################


########################
# Open the ROOT pom.xml file for this component
########################
rootpomfile="pom.xml"
io = File.open(rootpomfile, 'r')
@xml_doc = Nokogiri::XML(io)
io.close
puts "pom.xml"
########################

########################
# First, find all strings in the xml that say "version"
########################
@myversion = @xml_doc.css(node_name='version')
# puts @myversion
########################

updatedversion=""

########################
# First, of all of the pom-files, we need to process the top-level pom file for this component, and then act accordingly.
# * Top-level POMs need to have their parent version set to 1.2.1-a, which is the ccpParentPom's latest released-version.
#   This will prevent us from building a release on a snapshot.
# * We need to grab the top-level POM's version.  That will be pushed to all secondary POM's as the version, coupled with the build number argument to this script
########################
# Next, we need a for loop for each instance
@myversion.each do |version_instance|
  # puts version_instance
  myfirstparent = version_instance.parent # This should equal either "parent" or "project"
  # puts myfirstparent.name
  if myfirstparent.name == "project"
     puts "FILE: "+rootpomfile+" - CHANGING - 'version' parent is 'project' -- ROOT POM FILE, steal version info & concatenate with build ID"
     version_instance.content=tag_name
  elsif myfirstparent.name == "parent"
    mysecondparent = myfirstparent.parent # If the former equaled "parent", then this should equal "project"
    # puts mysecondparent.name
    if mysecondparent.name == "project"
       puts "FILE: "+rootpomfile+" - NOT CHANGING - 'version' parent is 'parent', grandparent is 'project' -- ROOT POM FILE, leave as currently set version"
       version_instance.content = "1.2.1-a"
    else
      puts"FILE: "+rootpomfile+" - NOT CHANGING - 'version' parent is 'parent', but grandparent is '"+mysecondparent.name+"'"
    end
  else
    puts"FILE: "+rootpomfile+" - NOT CHANGING - 'version' parent is '"+myfirstparent.name+"'"
  end
end
########################

########################
# Print out the xml file that has been updated
File.open(rootpomfile, 'w') {|f| f.write(@xml_doc) }
########################

########################
# Now, find all remaining POM files
########################
pom_file_locations = Dir["*/**/pom.xml"]
# puts pom_file_locations
pom_file_locations.each do |mypomfile|
########################

  ########################
  # Open the pom.xml file
  ########################
  io = File.open(mypomfile, 'r')
  @xml_doc = Nokogiri::XML(io)
  io.close
  ########################


  ########################
  # First, find all strings in the xml that say "version"
  ########################
  @myversion = @xml_doc.css(node_name='version')
  # puts @myversion
  ########################

  puts mypomfile

  ########################
  # First, of all of the pom-files, we need to process the top-level pom file for this component, and then act accordingly.
  # * Top-level POMs need to have their parent version set to 1.2.1-a, which is the ccpParentPom's latest released-version.
  #   This will prevent us from building a release on a snapshot.
  # * We need to grab the top-level POM's version.  That will be pushed to all secondary POM's as the version, coupled with the build number argument to this script
  ########################
  # Next, we need a for loop for each instance
  @myversion.each do |version_instance|
    # puts version_instance
    myfirstparent = version_instance.parent # This should equal either "parent" or "project"
    # puts myfirstparent.name
    if myfirstparent.name == "project"
       puts "FILE: "+mypomfile+" - CHANGING - 'version' parent is 'project'"
       version_instance.content=tag_name
    elsif myfirstparent.name == "parent"
      mysecondparent = myfirstparent.parent # If the former equaled "parent", then this should equal "project"
      # puts mysecondparent.name
      if mysecondparent.name == "project"
         puts "FILE: "+mypomfile+" - CHANGING - 'version' parent is 'parent', grandparent is 'project'"
         version_instance.content=tag_name
      else
        puts"FILE: "+mypomfile+" - NOT CHANGING - 'version' parent is 'parent', but grandparent is '"+mysecondparent.name+"'"
      end
    else
      puts"FILE: "+mypomfile+" - NOT CHANGING - 'version' parent is '"+myfirstparent.name+"'"
    end
  end
  ########################

  ########################
  # Print out the xml file that has been updated
  File.open(mypomfile, 'w') {|f| f.write(@xml_doc) }
  ########################

end
###
