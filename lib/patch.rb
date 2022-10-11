# frozen_string_literal: true

require "fileutils"
require "nokogiri"

class Reader
  attr_reader :dirpath

  def initialize(dirpath)
    @dirpath = dirpath
    @documents = {}
  end

  def read_doc(path)
    Dir.chdir(@dirpath) { Nokogiri::XML.parse(File.read(path)) }
  end

  def doc(path)
    @documents[path] ||= read_doc(path)
  end

  def doc_no_cache(path)
    read_doc(path)
  end

  def dir(path)
    Dir.chdir(@dirpath) do
      Dir[path].each { |p| yield doc_no_cache(p) }
    end
  end
end

def macro_path(reader, macro_name)
  macro = reader.doc("index/macros.xml").xpath("//index/entry[@name='#{macro_name}']/@value").first

  return unless macro

  macro.value.tr("\\", "/").gsub(/\Aextensions\/.+?\//, "") + ".xml"
end

def trade_ship_storage_macros(reader)
  macros = []

  reader.dir("#{reader.dirpath}/assets/units/*/macros/*.xml") do |doc|
    macro_name = doc.xpath("//macros/macro[properties[purpose[@primary='trade']]]" \
      "/connections/connection[contains(@ref, 'con_storage')]/macro/@ref")
      &.first&.value

    next unless macro_name

    path = macro_path(reader, macro_name)

    macros << path if path
  end

  macros.uniq
end

def build_for_dir(dirpath, target_path)
  reader = Reader.new(dirpath)

  trade_ship_storage_macros(reader).each do |path|
    target_absolute_path = File.join(target_path, path)
    target_dir = File.dirname(target_absolute_path)

    FileUtils.mkdir_p target_dir

    File.write target_absolute_path, <<~XML
      <?xml version="1.0" encoding="utf-8"?>

      <diff>
        <replace sel="//macros/macro/properties/cargo/@tags">container liquid solid condensate</replace>
      </diff>
    XML
  end
end

def build_patch(extracted_path, target_path)
  build_for_dir(extracted_path, target_path)

  Dir["#{extracted_path}/extensions/*"].each do |mod_path|
    relative_mod_path = Pathname.new(mod_path).relative_path_from(Pathname.new(extracted_path)).to_s

    extracted_mod_path = File.join(extracted_path, relative_mod_path)
    target_mod_path = File.join(target_path, relative_mod_path)

    build_for_dir(extracted_mod_path, target_mod_path)
  end
end
