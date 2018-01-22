library work;

package body pace_pkg is

  function NULL_TO_AUDIO return to_AUDIO_t is
  begin
    return ('0', (others => '0'), (others => '0'));
  end NULL_TO_AUDIO;

  function NULL_TO_SOUND return to_SOUND_t is
  begin
    return ((others => '0'), (others => '0'), '0', '0');
  end NULL_TO_SOUND;
  
  function NULL_TO_GP return to_GP_t is
  begin
    return ((others => '0'), (others => '0'));
  end NULL_TO_GP;

end package body pace_pkg;
