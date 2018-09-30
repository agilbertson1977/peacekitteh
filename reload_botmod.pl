sub reload {
  #undef($settings);
  $settings = decode_json(read_text($settings_file));
  return { public => "All settings reloaded" };
}

1;
