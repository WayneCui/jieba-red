Red []

han: charset [#"^(4E00)" - #"^(9FD5)"]
alpha: charset [#"a" - #"z" #"A" - #"Z"]
num: charset [#"0" - #"9"]
alphanum: union alpha num
non-space: charset [#"+" #"#" #"&" #"." #"_" #"-"]

han-default: union union han alphanum non-space
skip-default: charset [#"^^" #"^M" #" "]
han-cut-all: han
skip-cut-all: charset [not #"0"-#"9" #"a"-#"z" #"A"-#"Z" #"+" #"#" #"^^" #"^M"]  ;lf: #"^^" cr: #"^M"

DICT_WRITING: copy []
DEFAULT_DICT: NONE
DEFAULT_DICT_NAME: copy "dict.txt"

tokenizer: make object! [
    dictionary: NONE
    FREQ: []
    total: 0
    user_word_tag_tab: copy []
    initialized: false
    tmp_dir: NONE
    cache_file: %jieba.cache

    get_DAG: function [sentence][
        
        if (length? self/FREQ) == 0 [
            start: now/time
            gen_pfdict DEFAULT_DICT_NAME
            print rejoin ["gen_pfdict:" (now/time - start)]
        ]

        DAG: make map! []
        N: length? sentence
        repeat k N [
            tmplist: copy []
            i: k
            frag: to-string sentence/(k)
            ; print frag

            while [i <= N  and (not none? find self/FREQ frag) ][
                if not zero? self/FREQ/(frag) [
                    append tmplist i
                ]

                i: i + 1
                frag: copy/part at sentence k (i - k + 1)
            ]

            if (length? tmplist) = 0 [
                append tmplist k
            ]

            DAG/(k): tmplist
        ]

        DAG
    ]

    cut-all: function [sentence][
        dag: self/get_DAG sentence
        ; probe dag

        old-index: -1
        result: copy []
        foreach key keys-of dag [
            list: select dag key
            either ((length? list) = 1) and (key > old-index) [
                append result copy/part at sentence key (list/1 - key + 1)
            ][
                foreach index list [
                    if index > key [
                        print copy/part at sentence key (index - key + 1)
                        append result copy/part at sentence key (index - key + 1)
                        old-index: index
                    ]
                ]
            ]
        ]

        result
    ]

    cut_DAG_NO_HMM: function [][
        
    ]

    cut_DAG: function [][
        
    ]

    gen_pfdict: function [dictfilename][
        either exists? cache_file [
            cache: load cache_file
            self/total: to-integer cache/2
            self/FREQ: cache/1
        ][
            lfreq: make map! []
            ltotal: 0
            lines: read/lines to-file dictfilename
            foreach line lines [
                blk: split line space
                word: blk/1
                freq: to-integer blk/2
                lfreq/(word): freq
                ltotal: ltotal + freq
                repeat i length? word [
                    wfrag: take/part copy word i
                    if not lfreq/(wfrag) [
                        lfreq/(wfrag): 0
                    ]
                ]
            ]

            self/FREQ: lfreq
            self/total: ltotal

            write cache_file mold reduce [lfreq ltotal]
        ]
    ]   
]


cut: function [ 
        {
            The main function that segments an entire sentence that contains
            Chinese characters into separated words.
        }
        sentence "The str(unicode) to be segmented."
        /cut-all "Model type. True for full pattern, False for accurate pattern."
        /HMM "Whether to use the Hidden Markov Model."
    ][
    
    either cut-all [
        re_han: han-cut-all
        re_skip: skip-cut-all
    ] [
        re_han: han-default
        re_skip: skip-default
    ]


    ; either cut-all [
        
    ; ][
    ;     either HMM [

    ;     ][

    ;     ]
    ; ]

    blocks: parse sentence [ 
        collect [
            any [
                keep some han-default | skip
            ]
        ]
    ]

    result: copy []
    foreach blk blocks [
        ; print blk

        if parse blk [ some re_han] [
            foreach word tokenizer/cut-all blk [
                append result word
            ]
        ]
    ]

    result
]

start: now/time
sentence: "本质上是一个分布式数据库，允许多台服务器协同工作，每台服务器可以运行多个实例"
probe cut/cut-all sentence
print rejoin ["cost:" (now/time - start)]

