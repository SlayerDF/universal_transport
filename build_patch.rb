# frozen_string_literal: true

##
# Script to automate creation of xml patch files
# for every transport ship storage macros
#

require "fileutils"

files = Dir["assets/**/storage_*trans_container*.xml"].each do |filepath|
  content = File.read(filepath)

  patch_path = File.join("@patch", filepath)
  patch_dir = File.dirname(patch_path)

  patch_content = <<~XML
    <?xml version="1.0" encoding="utf-8"?>

    <diff>
      <replace sel="//macros/macro/properties/cargo/@tags">container liquid solid</replace>
    </diff>
  XML

  FileUtils.mkdir_p(patch_dir)
  File.write(patch_path, patch_content)
end
