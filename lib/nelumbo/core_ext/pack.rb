class String
	# Unpacks a Furcadia protocol string. TODO: document this.
	def furc_unpack(format, offset=0)
		output = []

		format.each_char do |piece|
			case piece
			when 'x'
				# Skip
				offset += 1

			when 'k', 'K'
				# Colour code: lowercase = colours only, uppercase = full code
				cc_format = self[offset]
				cc_size = (piece == 'K') ? 13 : 10
				if cc_format == 't'
					output << slice(offset, cc_size + 1)
					offset += cc_size + 1
				else
					raise "unsupported colour code type: #{cc_format}"
				end

			when 's', 'S'
				# Base 95/220 string: lowercase = 95, uppercase = 220
				base = (piece == 'S') ? 35 : 32
				length = getbyte(offset) - base
				output << slice(offset+1, length)
				offset += length + 1

			when 'a'..'f'
				# Base 95 big-endian integer: a = 1 digit, b = 2 digits, c = 3 digits, ...
				digits = piece.ord - 96
				output << slice(offset, digits).decode_b95
				offset += digits

			when 'A'..'F'
				# Base 220 little-endian integer: A = 1 digit, B = 2 digits, C = 3 digits, ...
				digits = piece.ord - 64
				output << slice(offset, digits).decode_b220
				offset += digits

			end
		end

		return output.first if output.size == 1
		output
	end
end


class Array
	# Packs a Furcadia protocol string. TODO: document this.
	def furc_pack(format)
		output = ''.force_encoding(Encoding::BINARY)

		self.zip(format.chars) do |element, piece|
			case piece
			when 'x'
				# Pass this bit through directly
				output << element

			when 'k', 'K'
				# Colour code: lowercase = colours only, uppercase = full code
				cc_size = (piece == 'K') ? 13 : 10
				if element.start_with? 't'
					cc = element.slice(0,cc_size+1).ljust(cc_size+1,'#')
					output << cc
				else
					raise "unsupported colour code type: #{element[0]}"
				end

			when 's', 'S'
				# Base 95/220 string: lowercase = 95, uppercase = 220
				base = (piece == 'S') ? 35 : 32
				output << (base + element.length).chr
				output << element

			when 'a'..'f'
				# Base 95 big-endian integer: a = 1 digit, b = 2 digits, c = 3 digits, ...
				digits = piece.ord - 96
				output << element.encode_b95(digits)

			when 'A'..'F'
				# Base 220 little-endian integer: A = 1 digit, B = 2 digits, C = 3 digits, ...
				digits = piece.ord - 64
				output << element.encode_b220(digits)

			end
		end

		output
	end
end

