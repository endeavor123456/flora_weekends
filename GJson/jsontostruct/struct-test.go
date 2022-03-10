package main

import (
	"encoding/json"
	"fmt"
)

type ConnectionInfo struct {
	JdbcUrl []string `json:"jdbcUrl"`
	Table   []string `json:"table"`
}

type ParameterDetail struct {
	Username   string           `json:"username"`
	Password   string           `json:"password"`
	Column     []string         `json:"column"`
	SplitPk    string           `json:"splitPk"`
	Connection []ConnectionInfo `json:"connection"`
}

type ReaderInfo struct {
	Name      string          `json:"name"`
	Parameter ParameterDetail `json:"parameter"`
}

type WriterInfo struct {
	Name      string          `json:"name"`
	Parameter ParameterDetail `json:"parameter"`
}

type ContentDetail struct {
	Reader ReaderInfo `json:"reader"`
	Writer WriterInfo `json:"writer"`
}

type JobInfo struct {
	Content []ContentDetail `json:"content"`
}

//层次用嵌套 平级用切结构体类型的切片  一个json对象 对应一个结构体
//json数组用结构体类型切片  如果json数组中只有一个json对象 直接写一一个结构体即可
// job
type JobDetail struct {
	Job JobInfo `json:"job"`
}

func main666() {

	var data string = `{
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
	  }`
	var job = JobDetail{
		JobInfo{
			[]ContentDetail{
				{
					ReaderInfo{
						Name: "postgresqlreader",
						Parameter: ParameterDetail{
							Username: data.ReaderUname(),
							Password: data.ReaderPwd(),
							Column: []string{
								"*",
							},
							SplitPk: "id",
							Connection: []ConnectionInfo{
								{
									JdbcUrl: []string{
										readerJDBC,
									},
									Table: []string{
										"dash_menu",
									},
								},
							},
						},
					},
					WriterInfo{
						Name: "postgresqlwriter",
						Parameter: ParameterDetail{
							Username: data.WriterUname(),
							Password: data.WriterPwd(),
							Column: []string{
								"*",
							},
							SplitPk: "id",
							Connection: []ConnectionInfo{
								{
									JdbcUrl: []string{
										writerJDBC,
									},
									Table: []string{
										"dash_menu",
									},
								},
							},
						},
					},
				},
			},
		},
	}
	// json写入文件
	jsonStr, _ := json.MarshalIndent(job, "", "\t")
	fmt.Println(jsonStr)
}
