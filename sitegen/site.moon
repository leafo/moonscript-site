
-- this is a sample site

require "sitegen"

site = sitegen.new {
  template_dir: "tempates/"
  page_dir: "pages"
  root_template: "root"
}

site\write!

