class CountryDifficulty {
  static const Set<String> easy = {
    'US', 'CA', 'GB', 'FR', 'DE', 'IT', 'ES', 'PT', 'JP', 'CN',
    'KR', 'AU', 'NZ', 'BR', 'AR', 'MX', 'IN', 'RU', 'ZA', 'NG',
    'EG', 'SA', 'AE', 'TR', 'SE', 'NO', 'FI', 'DK', 'NL', 'BE',
    'CH', 'AT', 'PL', 'GR', 'PH', 'TH', 'ID', 'VN', 'MY', 'SG',
    'CL', 'CO', 'PE', 'KE', 'MA', 'UA', 'HU', 'RO', 'IE',
  };

  static const Set<String> medium = {
    'AF', 'AL', 'DZ', 'AO', 'AM', 'AZ', 'BH', 'BD', 'BY', 'BJ',
    'BO', 'BA', 'BW', 'BN', 'BF', 'BI', 'CM', 'CF', 'TD', 'CG',
    'CD', 'CR', 'HR', 'CU', 'CY', 'CZ', 'EC', 'ET', 'FJ', 'GA',
    'GH', 'GT', 'GN', 'HT', 'HN', 'IQ', 'IR', 'IL', 'JM', 'JO',
    'KZ', 'KW', 'KG', 'LA', 'LB', 'LY', 'LT', 'LU', 'MG', 'MW',
    'ML', 'MR', 'MN', 'ME', 'MZ', 'MM', 'NA', 'NP', 'NI', 'NE',
    'MK', 'OM', 'PK', 'PA', 'PG', 'PY', 'QA', 'RS', 'RW', 'SN',
    'SL', 'SK', 'SI', 'SO', 'SD', 'SS', 'LK', 'SY', 'TZ', 'TG',
    'TN', 'TM', 'UG', 'UZ', 'VE', 'YE', 'ZM', 'ZW', 'EE', 'LV',
    'MD', 'GE', 'TJ', 'KH', 'BG', 'DO', 'SV', 'GQ', 'ER',
  };

  // Everything not in easy or medium is hard
  static bool isEasy(String cca2) => easy.contains(cca2);
  static bool isMedium(String cca2) => medium.contains(cca2);
  static bool isHard(String cca2) => !easy.contains(cca2) && !medium.contains(cca2);
}
