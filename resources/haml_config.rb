# encoding: UTF-8

# add functionality if Haml exists.
if defined? Haml
	# place the Anorexic::FeedHaml in the top-level namespace (main)
	# Since there is no specific view class, this allows direct access to the Anorexic::FeedHaml helpers
	require 'anorexic_feed_haml'
	include Anorexic::FeedHaml
end

# working on ActiveView stand alone...
# if defined? ActionView
# 	ActionView::Renderer.new(ActionView::LookupContext.new(ActionView::PathSet.new(["views"])))
# end