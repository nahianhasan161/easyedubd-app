import pathlib

p = pathlib.Path('lib/features/presentation/screens/courses/widgets/course_card.dart')
text = p.read_text()

price_start = text.find('if (!isFree && course.price != null) ...[', 4000)
# Find the next top-level if/else block after the price block
# The block ends before '                  ] else if (!isFree && course.price == null)'
price_end = text.find('                  ] else if (!isFree && course.price == null)', price_start)
price_block = text[price_start:price_end]

# Remove small inline -20% from price block
price_block = price_block.replace('''                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '-20%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),''', '')

# Increase offer price size
price_block = price_block.replace('fontSize: 14,', 'fontSize: 20,')
price_block = price_block.replace('fontSize: 13,', 'fontSize: 18,')

# Remove the old price block from text
new_text = text[:price_start] + text[price_end:]

# Now insert price block after description
desc_end = new_text.find('                  ),\n\n                  if (isEnrolled)', 1000)
# Find the closing of description Text widget
desc_end = new_text.find('                  ),', new_text.find('// DESCRIPTION'))
desc_end = new_text.find('                  ),', desc_end) + len('                  ),')

insert = '''\n\n                  if (!isFree && course.price != null) ...[\n                    const SizedBox(height: 14),\n                    Align(\n                      alignment: Alignment.centerRight,\n                      child: Wrap(\n                        crossAxisAlignment: WrapCrossAlignment.center,\n                        children: [\n                          Text(\n                            '৳${(course.price!).toStringAsFixed(0)}',\n                            style: TextStyle(\n                              fontSize: 18,\n                              color: Colors.grey.shade600,\n                              decoration: TextDecoration.lineThrough,\n                              decorationColor: Colors.grey.shade600,\n                            ),\n                          ),\n                          const SizedBox(width: 10),\n                          Container(\n                            padding: const EdgeInsets.symmetric(\n                              horizontal: 10,\n                              vertical: 4,\n                            ),\n                            decoration: BoxDecoration(\n                              color: const Color(0xFFFFF1B8),\n                              borderRadius: BorderRadius.circular(8),\n                            ),\n                            child: Text(\n                              '৳${(course.price! * 0.8).toStringAsFixed(0)}',\n                              style: const TextStyle(\n                                fontSize: 20,\n                                fontWeight: FontWeight.w700,\n                                color: Color(0xFF7A4F01),\n                              ),\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                    if (!isEnrolled && onEnroll != null) ...[\n                      const SizedBox(height: 10),\n                      SizedBox(\n                        width: double.infinity,\n                        child: ElevatedButton(\n                          onPressed: onEnroll,\n                          style: ElevatedButton.styleFrom(\n                            backgroundColor: const Color(0xFFE6A817),\n                            foregroundColor: Colors.white,\n                            padding: const EdgeInsets.symmetric(vertical: 10),\n                            shape: RoundedRectangleBorder(\n                              borderRadius: BorderRadius.circular(12),\n                            ),\n                          ),\n                          child: const Text(\n                            'Enroll Now',\n                            style: TextStyle(\n                              fontWeight: FontWeight.w700,\n                              fontSize: 14,\n                            ),\n                          ),\n                        ),\n                      ),\n                    ],\n                  ] else if (!isFree && course.price == null)\n                    Align(\n                      alignment: Alignment.centerRight,\n                      child: Row(\n                        mainAxisAlignment: MainAxisAlignment.end,\n                        children: [\n                          Text(\n                            'Paid',\n                            style: theme.textTheme.bodySmall?.copyWith(\n                              fontWeight: FontWeight.w600,\n                              color: Colors.grey.shade700,\n                            ),\n                          ),\n                          if (!isEnrolled && onEnroll != null) ...[\n                            const SizedBox(width: 10),\n                            ElevatedButton(\n                              onPressed: onEnroll,\n                              style: ElevatedButton.styleFrom(\n                                backgroundColor: const Color(0xFFE6A817),\n                                foregroundColor: Colors.white,\n                                padding: const EdgeInsets.symmetric(\n                                  horizontal: 14,\n                                  vertical: 8,\n                                ),\n                                shape: RoundedRectangleBorder(\n                                  borderRadius: BorderRadius.circular(12),\n                                ),\n                              ),\n                              child: const Text(\n                                'Enroll Now',\n                                style: TextStyle(\n                                  fontWeight: FontWeight.w700,\n                                  fontSize: 13,\n                                ),\n                              ),\n                            ),\n                          ],\n                        ],\n                      ),\n                    ),'''

new_text = new_text[:desc_end] + insert + new_text[desc_end:]
p.write_text(new_text)
print('OK')
