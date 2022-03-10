package countrymanager

import (
	"ma.applysquare.net/eng/flora/pkg/core/gen/h"
	"ma.applysquare.net/eng/flora/pkg/core/models"
)

func init() {
	// DemoCountry 是模型的名字，一会儿将自动生成一个 demo_country.go 的文件
	country := h.DemoCountry().DeclareModel()

	// 给模型添加各种字段
	// 字段的类型如 CharField、DateField 等可 flora 文档查看
	country.AddFields(map[string]models.FieldDefinition{
		"Name": models.CharField{
			Description: "名称",
			Required:    true, //必填 是就填true 不是就不用写
			Unique:      true, //唯一 是就填true 不是就不用写
		},
		"Capital": models.CharField{
			Description: "首都",
			Required:    true,
			Unique:      true,
		},
		"Population": models.IntegerField{
			Description: "人口",
			Required:    true,
		},
		"Area": models.FloatField{
			Description: "面积",
			Required:    true,
		},
		"Language": models.CharField{
			Description: "语言",
			Required:    true,
		},
		"Introduce": models.TextField{
			//必填 是就填true 不是就不用写
		},
	})
}
