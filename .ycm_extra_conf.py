def Settings( **kwargs ):
    return {
            'flags':['-x', 'c', '-Wall', '-Wextra', '-I./src/include', '-Wno-unused-function',
                     '-std=gnu2x'],
            }

