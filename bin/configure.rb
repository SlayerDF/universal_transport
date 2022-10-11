#!/usr/bin/env ruby

EXTRACT_DIR = File.join(File.dirname(__FILE__), "..", "extracted")
BUILD_DIR = File.join(File.dirname(__FILE__), "..", "dist")

require_relative "../lib/patch"
require_relative "../lib/unpack"
