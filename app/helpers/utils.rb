def format_number(number)
  number = '%.2f' % number
  number = number.split('.')
  parts = number[0].reverse!.split('').each_slice(3).map {|a| a.join('')}
  '%s.%s' % [parts.join(',').reverse!, number[1]]
end

