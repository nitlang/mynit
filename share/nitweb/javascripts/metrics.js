/*
 * Copyright 2016 Alexandre Terrasa <alexandre@moz-code.org>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
	angular
		.module('metrics', ['model'])

		.directive('metricsList', function() {
			return {
				restrict: 'E',
				scope: {
					listId: '@',
					listTitle: '@',
					listMetrics: '=',
					listMetricsNames: '=',
					listMetricsDefault: '='
				},
				templateUrl: '/directives/metrics/metrics_list.html'
			};
		})

		.directive('chartModuleDefinitionsKind', function() {
			return {
				restrict: 'E',
				scope: {
					chartId: '@',
					chartMetrics: '='
				},
				templateUrl: '/directives/metrics/chart_properties.html',
				link: function ($scope, element, attrs) {
					$scope.loadChart = function() {
						if($scope.chart) { return; }
						$scope.chart = new d3pie($scope.chartId, {
							"header": {
								"title": {
									"fontSize": 24,
									"font": "open sans"
								},
								"subtitle": {
									"color": "#999999",
									"fontSize": 12,
									"font": "open sans"
								},
								"titleSubtitlePadding": 9
							},
							"size": {
								"canvasHeight": 200,
								"canvasWidth": 350,
								"pieOuterRadius": "80%"
							},
							"data": {
								"sortOrder": "value-asc",
								"content": [
									{
										"label": "Concrete classes",
										"value": $scope.chartMetrics.MNBICC.avg,
										"color": "#228835"
									},
									{
										"label": "Abstract classes",
										"value": $scope.chartMetrics.MNBIAC.avg,
										"color": "#103EB8"
									},
									{
										"label": "Interfaces",
										"value": $scope.chartMetrics.MNBII.avg,
										"color": "#e65314"
									}
								]
							},
							"labels": {
								"outer": {
									"format": "label-value2",
									"pieDistance": 20
								},
								"inner": {
									"hideWhenLessThanPercentage": 3
								},
								"mainLabel": {
									"fontSize": 11
								},
								"percentage": {
									"color": "#ffffff",
									"decimalPlaces": 0
								},
								"value": {
									"color": "#adadad",
									"fontSize": 11
								},
								"lines": {
									"enabled": true,
									"style": "straight"
								},
								"truncation": {
									"enabled": true
								}
							}
						});
					};

					$scope.$watch('chartMetrics', function(nv, ov) {
						if(nv) {
							setTimeout($scope.loadChart, 100);
						}
					});
				}
			};
		})

		.directive('chartModuleDefinitionsInh', function() {
			return {
				restrict: 'E',
				scope: {
					chartId: '@',
					chartMetrics: '='
				},
				templateUrl: '/directives/metrics/chart_properties.html',
				link: function ($scope, element, attrs) {
					$scope.loadChart = function() {
						if($scope.chart) { return; }
						$scope.chart = new d3pie($scope.chartId, {
							"header": {
								"title": {
									"fontSize": 24,
									"font": "open sans"
								},
								"subtitle": {
									"color": "#999999",
									"fontSize": 12,
									"font": "open sans"
								},
								"titleSubtitlePadding": 9
							},
							"size": {
								"canvasHeight": 200,
								"canvasWidth": 350,
								"pieOuterRadius": "80%"
							},
							"data": {
								"sortOrder": "value-asc",
								"content": [
									{
										"label": "Imported",
										"value": $scope.chartMetrics.MNBHC.avg,
										"color": "#999999"
									},
									{
										"label": "Introduced",
										"value": $scope.chartMetrics.MNBIC.avg,
										"color": "#228835"
									},
									{
										"label": "Redefined",
										"value": $scope.chartMetrics.MNBRC.avg,
										"color": "#e65314"
									}
								]
							},
							"labels": {
								"outer": {
									"format": "label-value2",
									"pieDistance": 20
								},
								"inner": {
									"hideWhenLessThanPercentage": 3
								},
								"mainLabel": {
									"fontSize": 11
								},
								"percentage": {
									"color": "#ffffff",
									"decimalPlaces": 0
								},
								"value": {
									"color": "#adadad",
									"fontSize": 11
								},
								"lines": {
									"enabled": true,
									"style": "straight"
								},
								"truncation": {
									"enabled": true
								}
							}
						});
					};

					$scope.$watch('chartMetrics', function(nv, ov) {
						if(nv) {
							setTimeout($scope.loadChart, 100);
						}
					});
				}
			};
		})

		.directive('chartClassPropertiesInh', function() {
			return {
				restrict: 'E',
				scope: {
					chartId: '@',
					chartMetrics: '='
				},
				templateUrl: '/directives/metrics/chart_properties.html',
				link: function ($scope, element, attrs) {
					$scope.loadChart = function() {
						if($scope.chart) { return; }
						$scope.chart = new d3pie($scope.chartId, {
							"header": {
								"title": {
									"fontSize": 24,
									"font": "open sans"
								},
								"subtitle": {
									"color": "#999999",
									"fontSize": 12,
									"font": "open sans"
								},
								"titleSubtitlePadding": 9
							},
							"size": {
								"canvasHeight": 200,
								"canvasWidth": 350,
								"pieOuterRadius": "80%"
							},
							"data": {
								"sortOrder": "value-asc",
								"content": [
									{
										"label": "Inherited",
										"value": $scope.chartMetrics.CNBHP.avg,
										"color": "#999999"
									},
									{
										"label": "Introduced",
										"value": $scope.chartMetrics.CNBIP.avg,
										"color": "#228835"
									},
									{
										"label": "Redefined",
										"value": $scope.chartMetrics.CNBRP.avg,
										"color": "#e65314"
									}
								]
							},
							"labels": {
								"outer": {
									"format": "label-value2",
									"pieDistance": 20
								},
								"inner": {
									"hideWhenLessThanPercentage": 3
								},
								"mainLabel": {
									"fontSize": 11
								},
								"percentage": {
									"color": "#ffffff",
									"decimalPlaces": 0
								},
								"value": {
									"color": "#adadad",
									"fontSize": 11
								},
								"lines": {
									"enabled": true,
									"style": "straight"
								},
								"truncation": {
									"enabled": true
								}
							}
						});
					};

					$scope.$watch('chartMetrics', function(nv, ov) {
						if(nv) {
							setTimeout($scope.loadChart, 100);
						}
					});
				}
			};
		})

		.directive('chartClassPropertiesKind', function() {
			return {
				restrict: 'E',
				scope: {
					chartId: '@',
					chartMetrics: '='
				},
				templateUrl: '/directives/metrics/chart_properties.html',
				link: function ($scope, element, attrs) {
					$scope.loadChart = function() {
						if($scope.chart) { return; }
						$scope.chart = new d3pie($scope.chartId, {
							"header": {
								"title": {
									"fontSize": 24,
									"font": "open sans"
								},
								"subtitle": {
									"color": "#999999",
									"fontSize": 12,
									"font": "open sans"
								},
								"titleSubtitlePadding": 9
							},
							"size": {
								"canvasHeight": 200,
								"canvasWidth": 350,
								"pieOuterRadius": "80%"
							},
							"data": {
								"sortOrder": "value-asc",
								"content": [
									{
										"label": "Attributes",
										"value": $scope.chartMetrics.CNBIPA.avg,
										"color": "#228835"
									},
									{
										"label": "Methods",
										"value": $scope.chartMetrics.CNBIPM.avg,
										"color": "#999999"
									},
									{
										"label": "Constructors",
										"value": $scope.chartMetrics.CNBIPI.avg,
										"color": "#e65314"
									},
									{
										"label": "Virtual Types",
										"value": $scope.chartMetrics.CNBIVT.avg,
										"color": "#103EB8"
									}
								]
							},
							"labels": {
								"outer": {
									"format": "label-value2",
									"pieDistance": 20
								},
								"inner": {
									"hideWhenLessThanPercentage": 3
								},
								"mainLabel": {
									"fontSize": 11
								},
								"percentage": {
									"color": "#ffffff",
									"decimalPlaces": 0
								},
								"value": {
									"color": "#adadad",
									"fontSize": 11
								},
								"lines": {
									"enabled": true,
									"style": "straight"
								},
								"truncation": {
									"enabled": true
								}
							}
						});
					};

					$scope.$watch('chartMetrics', function(nv, ov) {
						if(nv) {
							setTimeout($scope.loadChart, 100);
						}
					});
				}
			};
		})

		.directive('chartClassInheritanceKind', function() {
			return {
				restrict: 'E',
				scope: {
					chartId: '@',
					chartMetrics: '='
				},
				templateUrl: '/directives/metrics/chart_properties.html',
				link: function ($scope, element, attrs) {
					$scope.loadChart = function() {
						if($scope.chart) { return; }
						$scope.chart = new d3pie($scope.chartId, {
							"header": {
								"title": {
									"fontSize": 24,
									"font": "open sans"
								},
								"subtitle": {
									"color": "#999999",
									"fontSize": 12,
									"font": "open sans"
								},
								"titleSubtitlePadding": 9
							},
							"size": {
								"canvasHeight": 200,
								"canvasWidth": 350,
								"pieOuterRadius": "80%"
							},
							"data": {
								"sortOrder": "value-asc",
								"content": [
									{
										"label": "Interfaces",
										"value": $scope.chartMetrics.cnoai.avg,
										"color": "#228835"
									},
									{
										"label": "Abstract classes",
										"value": $scope.chartMetrics.cnoaa.avg,
										"color": "#103EB8"
									},
									{
										"label": "Concrete classes",
										"value": $scope.chartMetrics.cnoac.avg - $scope.chartMetrics.cnoaa.avg,
										"color": "#e65314"
									}
								]
							},
							"labels": {
								"outer": {
									"format": "label-value2",
									"pieDistance": 20
								},
								"inner": {
									"hideWhenLessThanPercentage": 3
								},
								"mainLabel": {
									"fontSize": 11
								},
								"percentage": {
									"color": "#ffffff",
									"decimalPlaces": 0
								},
								"value": {
									"color": "#adadad",
									"fontSize": 11
								},
								"lines": {
									"enabled": true,
									"style": "straight"
								},
								"truncation": {
									"enabled": true
								}
							}
						});
					};

					$scope.$watch('chartMetrics', function(nv, ov) {
						if(nv) {
							setTimeout($scope.loadChart, 100);
						}
					});
				}
			};
		})
})();
