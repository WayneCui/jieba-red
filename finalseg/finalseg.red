Red [
    Title: ""
]

MIN_FLOAT: -3.14e100

PROB_START: %prob_start.red
PROB_TRANS: %prob_trans.red
PROB_EMIT: %prob_emit.red

status: ['B 'E 'M 'S]

prev-status: [
    'B ['E 'S]
    'M ['M 'B]
    'S ['S 'E]
    'E ['B 'M]
]

start-p: load PROB_START
trans-p: load PROB_TRANS
emit-p: load PROB_EMIT

viterbi: function [ observed [string!] ][
    weight: copy [ #() ]
    path: make map! []

    foreach state status [
        emit-prob-1: either none? emit-p/(state)/(to string! observed/1) [ MIN_FLOAT ][ emit-p/(state)/(to string! observed/1) ]
        weight/1/(state): start-p/(state) + emit-prob-1
        path/(state): reduce [state]
    ]

    repeat i ((length? observed) - 1) [
        append weight copy #()
        new-path: make map![]
        foreach state status [
            tmp: collect [
                foreach prev-state prev-status/(state) [
                    keep prev-state
                    keep weight/(i)/(prev-state) + trans-p/(prev-state)/(state) + emit-p/(state)/(to string! observed/(i + 1))
                ]
            ]

            w: sort/skip/compare/reverse copy tmp 2 2
            weight/(i + 1)/(state): w/2
            new-path/(state): append copy path/(w/1) state
        ]

        path: new-path
    ]

    ; probe weight
    ; probe path

    prob: last weight
    either prob/E > prob/S [
        path/E
    ][
        path/S
    ]
]

cut: function [ sentence ][
    
]

viterbi "小明硕士毕业于中国科学院计算所" ;should be ['B 'E 'B 'E 'B 'M 'E 'B 'E 'B 'M 'E 'B 'E 'S]