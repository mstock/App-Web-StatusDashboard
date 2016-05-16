(function () {
	'use strict';

	angular.module('StatusDashboard').directive('jiraIssues', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.chartLabels = []
					scope.chartSeries = [];
					scope.chartData = [ [] ];
					scope.chartOptions = {
						scales : {
							xAxes : [ {
								stacked : true
							} ],
							yAxes : [ {
								stacked : true
							} ]
						}
					};

					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}

						var statusStats = {};
						var issuetypes = {};
						newValue.forEach(function (issue) {
							var status = issue.fields.status;
							if (!statusStats[status.id]) {
								statusStats[status.id] = {
									id: status.id,
									name:  status.name,
									count: 0,
									issuetype: {}
								};
							}
							if (!statusStats[status.id].issuetype[issue.fields.issuetype.id]) {
								statusStats[status.id].issuetype[issue.fields.issuetype.id] = {
									id : issue.fields.issuetype.id,
									name : issue.fields.issuetype.name,
									count : 0
								}
							}
							statusStats[status.id].count++;
							statusStats[status.id].issuetype[issue.fields.issuetype.id].count++;
							if (!issuetypes[issue.fields.issuetype.id]) {
								issuetypes[issue.fields.issuetype.id] = {
									id : issue.fields.issuetype.id,
									name : issue.fields.issuetype.name,
								}
							}
						});
						var issuetypeList = [];
						Object.keys(issuetypes).forEach(function (issuetypeId) {
							issuetypeList.push(issuetypes[issuetypeId]);
						});
						issuetypeList.sort(function (a, b) {
							return a.name.localeCompare(b.name);
						});
						scope.chartSeries = issuetypeList.map(function (issuetype) {
							return issuetype.name;
						});
						scope.chartLabels.length = 0;
						scope.chartData.length = 0;
						Object.keys(statusStats).sort().forEach(function (id) {
							scope.chartLabels.push(statusStats[id].name);
							issuetypeList.forEach(function (issuetype, index) {
								if (!scope.chartData[index]) {
									scope.chartData[index] = [];
								}
								scope.chartData[index].push(
									statusStats[id].issuetype[issuetype.id]
										? statusStats[id].issuetype[issuetype.id].count
										: 0
								);
							});
						});
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/jira-issues.html',
				scope:       {
					statusId:    '@statusId',
					statusTitle: '@statusTitle'
				}
			}
		}
	]);
}());
