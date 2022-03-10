package main

import (
	"encoding/json"
	"fmt"
)

/*
"job": {
		  "setting": {
			"speed": {
			  "byte": 1048576
			},
			"errorLimit": {
			  "record": 0,
			  "percentage": 0.02
			}
		  },
		  "content": [
			{
			  "reader": {
				"name": "postgresqlreader",
				"parameter": {
				  "username": "postgres",
				  "password": "postgres",
				  "column": [
					"*"
				  ],
				  "splitPk": "id",
				  "connection": [
					{
					  "jdbcUrl": [
						"jdbc:postgresql://127.0.0.1:5432/flora-study"
					  ],
					  "table": [
						"dash_menu"
					  ]
					}
				  ]
				}
			  },
			  "writer": {
				"name": "postgresqlwriter",
				"parameter": {
				  "username": "postgres",
				  "password": "postgres",
				  "column": [
					"*"
				  ],
				  "splitPk": "id",
				  "connection": [
					{
					  "jdbcUrl": [
						"jdbc:postgresql://127.0.0.1:5432/jackal"
					  ],
					  "table": [
						"dash_menu"
					  ]
					}
				  ]
				}
			  }
			}
		  ]
		}
	  }
*/
type ConnInfo struct {
	JdbcUrl []string `json:"jdbcUrl"`
	Table   []string `json:"table"`
}
type Parameter struct {
	Username string   `json:"username"`
	Password string   `json:"password"`
	Column   []string `json:"colum"`
	SplitPk  int      `json:"splitPk"`
	ConnInfo []ConnInfo
}
type Reader struct {
	Name      string `json:"name"`
	Parameter Parameter
}
type ConnectInfo struct {
	Reader Reader
}

type Speed struct {
	Byte int `json:"byte"`
}
type ErrorLimit struct {
	Record     int     `json:"record"`
	Percentage float64 `json:"percentage"`
}
type Setting struct {
	Speed      Speed
	ErrorLimit ErrorLimit
}
type Job struct {
	Setting     Setting
	ConnectInfo []ConnectInfo
}
type Zone struct {
	Job Job
}

func main() {
	var zone Zone
	jsonStr, _ := json.MarshalIndent(zone, "", "\t")
	fmt.Println(string(jsonStr))
}
