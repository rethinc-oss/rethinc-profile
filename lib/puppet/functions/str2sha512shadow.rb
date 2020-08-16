Puppet::Functions.create_function(:str2sha512shadow) do
    dispatch :str2sha512shadow do
      param 'String', :password
      return_type 'String'
    end
  
    def str2sha512shadow(password)
        seeds = ('a'..'z').to_a
        seeds.concat( ('A'..'Z').to_a )
        seeds.concat( (0..9).to_a )
        seeds.concat ['/', '.']
        seeds.compact!

        salt_string = '$6$'
        8.times { salt_string << seeds[ rand(seeds.size) ].to_s }

        password.crypt( salt_string )
    end
  end