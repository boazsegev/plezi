# encoding: UTF-8
# place the Anorexic::FeedHaml in the top-level namespace (main)
# Since there is no specific view class, this allows direct access to the Anorexic::FeedHaml helpers

if defined? Anorexic::FeedHaml
	include Anorexic::FeedHaml
end

if defined? ActionView
	ActionView::Renderer.new(ActionView::LookupContext.new(ActionView::PathSet.new(["views"])))
end