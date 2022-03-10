package personmanager

import (
	"ma.applysquare.net/eng/flora/pkg/core/gen/h"
	"ma.applysquare.net/eng/flora/pkg/core/gen/m"
	"ma.applysquare.net/eng/flora/pkg/core/models"
)

func init() {
	// 声明一个空的模型，DemoStudent 是模型的名字，一会儿将自动生成一个 demo_student.go 的文件
	person := h.DemoPerson().DeclareModel()

	// 给模型添加各种字段
	// 字段的类型如 CharField、DateField 等可 flora 文档查看
	person.AddFields(map[string]models.FieldDefinition{
		"Name": models.CharField{
			Description: "姓名",
			Required:    true,
			Unique:      true,
		},
		"Age": models.IntegerField{
			Description: "年龄",
			String:      "年龄",
			Required:    true,
		},
		"Address": models.CharField{
			Description: "地址",
			String:      "地址",
			Required:    true,
			Stored:      true,
			Constraint:  person.Methods().ValidateAddress(),
		},
		"Height": models.FloatField{
			Description: "身高",
			String:      "身高",
			Required:    true,
		},
		"Weight": models.FloatField{
			Description: "体重",
			String:      "体重",
			Required:    true,
		},
		"Sex": models.CharField{
			Description: "性别",
			Required:    true,
		},
	})

	person.Methods().ValidateAddress().DeclareMethod(
		"校验地址长度",
		func(rs m.DemoPersonSet) {
			if len(rs.Address()) <= 5 {
				models.PanicValidationError(rs.Env().Ctx(), models.NewValidationError(person.Model, models.ValidationErrorItem{
					Level:   "field", // model
					Kind:    "address-error",
					Field:   "Address",
					Message: "您输入的地址有误，请重新输入",
				}))
			}
		})
}
