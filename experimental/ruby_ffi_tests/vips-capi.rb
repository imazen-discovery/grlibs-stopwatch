
require 'rubygems'
require 'ffi'

module Vips
  extend FFI::Library

  ffi_lib 'libvips.so.31'

  attach_function :im_open, [:string, :string], :pointer
  attach_function :im_close, [:pointer], :int


end
