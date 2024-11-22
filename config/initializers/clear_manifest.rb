if Rails.env.development?
  manifest_path = Rails.root.join('public', 'assets', '.manifest.json')
  File.delete(manifest_path) if File.exist?(manifest_path)
end

