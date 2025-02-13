# frozen_string_literal: true

require 'import_export/zip_utils'

module ThemeStore; end

class ThemeStore::TgzImporter

  attr_reader :url

  def initialize(filename)
    @temp_folder = "#{Pathname.new(Dir.tmpdir).realpath}/discourse_theme_#{SecureRandom.hex}"
    @filename = filename
  end

  def import!
    FileUtils.mkdir(@temp_folder)

    Dir.chdir(@temp_folder) do
      if @filename.include?('.zip')
        ZipUtils.new.unzip_directory(@temp_folder, @filename)

        # --strip 1 equivalent
        FileUtils.mv(Dir.glob("#{@temp_folder}/*/*"), @temp_folder)
      else
        Discourse::Utils.execute_command("tar", "-xzvf", @filename, "--strip", "1")
      end
    end
  rescue RuntimeError
    raise RemoteTheme::ImportError, I18n.t("themes.import_error.unpack_failed")
  end

  def cleanup!
    FileUtils.rm_rf(@temp_folder)
  end

  def version
    ""
  end

  def real_path(relative)
    fullpath = "#{@temp_folder}/#{relative}"
    return nil unless File.exist?(fullpath)

    # careful to handle symlinks here, don't want to expose random data
    fullpath = Pathname.new(fullpath).realpath.to_s

    if fullpath && fullpath.start_with?(@temp_folder)
      fullpath
    else
      nil
    end
  end

  def all_files
    Dir.chdir(@temp_folder) do
      Dir.glob("**/**").reject { |f| File.directory?(f) }
    end
  end

  def [](value)
    fullpath = real_path(value)
    return nil unless fullpath
    File.read(fullpath)
  end

end
