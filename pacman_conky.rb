#!/usr/bin/env ruby
# Add ${execpi 3600 path/to/conky_pacman.rb} to the bottom of ~/.conkyrc

CONKY_WIDTH  = 35
MAX_PACKAGES = 8
COLOR_INFO   = '#FFFFFF'
COLOR_HIGH   = '#FF0000'
COLOR_MED    = '#FFFF00'
COLOR_LOW    = '#FFFFFF'

packages        = []
update_count    = 0
update_info     = ''
sorted_packages = []

# PACKAGE RATING - prioritize packages by rating
# pkgs will be sorted by rating. pkg rating = ratePkg + rateRepo for that pkg
# pkg (default=0, wildcards accepted)
package_rating = { 
          'linux'  => 10,
          'pacman' => 9,
          'nvidia' => 8
          }
# # repo (default=0, wildcards accepted)
repo_rating = {
        'core'      => 5,
        'extra'     => 4,
        'community' => 3,
        'testing'   => 2,
        'unstable'  => 1
        }
# at what point is a pkg considered "important"
iThresh = 5

update_result = `pacman -Qu`

# split up packages
packages = update_result.split("\n")
# split name and version
packages.map! { |p| p.split }

update_count = packages.count()

case update_count
when 0
  update_info = "No updates available"
when 1
  update_info = "1 package has an update"
else
  update_info = "#{packages.count()} packages have an update"
end

# puts "Pacman:"
puts "${" + COLOR_INFO + "}#{update_info}${color}"

if update_count > 0
  # puts "-" * CONKY_WIDTH

  packages.each do |name, version|
    # pull in package info
    info = `pacman -Si #{name}`
    # grep package repo
    repo = info.match(/Repository.*:\s(.*)$/)[1]
    
    # rate package
    rating =  repo_rating[repo]    || 0
    rating += package_rating[name] || 0

    # build package details and add to array
    temp           = {}
    temp[:name]    = name
    temp[:version] = version
    temp[:repo]    = repo
    temp[:rating]  = rating
    sorted_packages << temp
  end
  
  # sort packages by rating (desc) and name (asc)
  sorted_packages.sort_by! { |p| [-p[:rating], p[:name]] }

  # find longest name so that I can align repos
  # TODO: when longest name is bigger than CONKY_WIDTH, while loop for first that fits
  longest_name = sorted_packages.max_by { |p| p[:name].length }
  longest_name_length = longest_name[:name].length

  # loop through sorted packages, show only the first so many (set by MAX_PACKAGES)
  sorted_packages[0..MAX_PACKAGES].each do |package|
    spacer         = ' '
    name_spacer    = ' '
    version_spacer = spacer

    # get the difference between the longest name and current, add spaces after name
    name_spacer_length = longest_name_length - package[:name].length + 1
    name_spacer = name_spacer * name_spacer_length

    # get total size of current package name, repo, and version, and space already added (1 space default)
    total_size = package[:name].length + package[:version].length + package[:repo].length + name_spacer_length + 1

    # if I can add spaces
    if CONKY_WIDTH > total_size
      # get the difference between the window and total length, add spaces after repo
      version_spacer_size = CONKY_WIDTH - total_size
      version_spacer = version_spacer * version_spacer_size
    end

    # assign color per repo
    case package[:repo]
    when 'core'
      package_color = COLOR_HIGH
    when 'extra'
      package_color = COLOR_MED
    else
      package_color = COLOR_LOW
    end

    puts "${" + package_color + "}#{package[:name]}#{name_spacer}[#{package[:repo]}]#{version_spacer}#{package[:version]}${color}"
  end
end
