# frozen_string_literal: true

require "rubygems"
require "bundler"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn "Run `bundle install` to install missing gems"
  exit e.status_code
end
require "rake"

require "jeweler"
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "unicode_scanner"
  gem.homepage    = "http://github.com/RISCfuture/unicode_scanner"
  gem.license     = "MIT"
  gem.summary     = %(Unicode-aware implementation of StringScanner)
  gem.description = %(An implementation of StringScanner that doesn't split multibyte characters.)
  gem.email       = "git@timothymorgan.info"
  gem.authors     = ["Tim Morgan"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require "rspec/core"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList["spec/**/*_spec.rb"]
end

task default: :spec

require "yard"

# bring sexy back (sexy == tables)
module YARD::Templates::Helpers::HtmlHelper
  def html_markup_markdown(text)
    markup_class(:markdown).new(text, :gh_blockcode, :fenced_code, :autolink, :tables).to_html
  end
end

YARD::Rake::YardocTask.new("doc") do |doc|
  doc.options << "-m" << "markdown" << "-M" << "redcarpet"
  doc.options << "--protected" << "--no-private"
  doc.options << "-r" << "README.md"
  doc.options << "-o" << "doc"
  doc.options << "--title" << "Unicode String Scanner Documentation"

  doc.files = %w[lib/**/* README.md]
end
