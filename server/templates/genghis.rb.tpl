#!/usr/bin/env ruby
#
# Genghis v<%= version %>
#
# The single-file MongoDB admin app
#
# http://genghisapp.com
#
# Copyright (c) 2011-2014 Justin Hileman
#
module Genghis
  VERSION = '<%= version %>'
end

<%= includes %>

Genghis::Server.run! if __FILE__ == $0

__END__

<%= assets %>
